import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/predictions/predictions_repo_impl.dart';
import '../core/remote/data/predictions/models/predictions_models.dart';
import '../services/shared_pref_services.dart';
import '../services/pref_keys.dart';

// ── User ID helper ─────────────────────────────────────────────────────────────

String _getOrCreateUserId() {
  final existing = SharedPreferenceService.getValue<String>(PrefKeys.userId);
  if (existing != null && existing.isNotEmpty) return existing;
  final generated = _generateId();
  SharedPreferenceService.setValue(PrefKeys.userId, generated);
  return generated;
}

String _generateId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
}

final _repo = PredictionsRepoImpl();

// ── Leaderboard ────────────────────────────────────────────────────────────────

// Family param is the timeframe string: '7d' | '30d' | '90d' | 'all'
final leaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, timeframe) async {
  return _repo.fetchLeaderboard(timeframe: timeframe);
});

// ── Coin Accuracy (per coin) ───────────────────────────────────────────────────

final coinAccuracyProvider =
    FutureProvider.autoDispose.family<CoinAccuracy, String>((ref, coinId) async {
  return _repo.fetchAccuracy(coinId);
});

// ── Prediction History (per coin) ─────────────────────────────────────────────

final predictionHistoryProvider =
    FutureProvider.autoDispose
        .family<List<PredictionRecord>, String>((ref, coinId) async {
  return _repo.fetchHistory(coinId);
});

// ── Post Mortems (per coin) ────────────────────────────────────────────────────

final postMortemsProvider =
    FutureProvider.autoDispose
        .family<List<PostMortem>, String>((ref, coinId) async {
  return _repo.fetchPostMortems(coinId);
});

// ── User Predictions Notifier ──────────────────────────────────────────────────

class UserPredictionsState {
  final String userId;
  final AsyncValue<List<PredictionRecord>> mine;
  final AsyncValue<UserVsAi> vsAi;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const UserPredictionsState({
    required this.userId,
    required this.mine,
    required this.vsAi,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  static UserPredictionsState initial(String userId) => UserPredictionsState(
        userId: userId,
        mine: const AsyncValue.loading(),
        vsAi: const AsyncValue.loading(),
      );

  UserPredictionsState copyWith({
    AsyncValue<List<PredictionRecord>>? mine,
    AsyncValue<UserVsAi>? vsAi,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) =>
      UserPredictionsState(
        userId: userId,
        mine: mine ?? this.mine,
        vsAi: vsAi ?? this.vsAi,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitError: submitError,
        submitSuccess: submitSuccess ?? this.submitSuccess,
      );
}

class UserPredictionsNotifier extends Notifier<UserPredictionsState> {
  @override
  UserPredictionsState build() {
    final userId = _getOrCreateUserId();
    final s = UserPredictionsState.initial(userId);
    _fetchAll(userId);
    return s;
  }

  Future<void> _fetchAll(String userId) async {
    await Future.wait([_fetchMine(userId), _fetchVsAi(userId)]);
  }

  Future<void> _fetchMine(String userId) async {
    try {
      final data = await _repo.fetchUserMine(userId);
      state = state.copyWith(mine: AsyncValue.data(data));
    } catch (e, st) {
      state = state.copyWith(mine: AsyncValue.error(e, st));
    }
  }

  Future<void> _fetchVsAi(String userId) async {
    try {
      final data = await _repo.fetchUserVsAi(userId);
      state = state.copyWith(vsAi: AsyncValue.data(data));
    } catch (e, st) {
      state = state.copyWith(vsAi: AsyncValue.error(e, st));
    }
  }

  Future<void> submit({
    required String coinId,
    required String coinSymbol,
    required String predictedDirection,
    required double entryPrice,
    double? predictedTarget,
    double? stopLoss,
    double? predictionWindowDays,
    double? confidenceScore,
    String? userReasoning,
  }) async {
    // Clear any previous error before each attempt
    state = UserPredictionsState(
      userId: state.userId,
      mine: state.mine,
      vsAi: state.vsAi,
      isSubmitting: true,
      submitSuccess: false,
    );
    try {
      final prediction = UserPrediction(
        userId: state.userId.isNotEmpty ? state.userId : null,
        coinId: coinId,
        coinSymbol: coinSymbol,
        predictedDirection: predictedDirection,
        entryPrice: entryPrice,
        predictedTarget: predictedTarget,
        stopLoss: stopLoss,
        predictionWindowDays: predictionWindowDays,
        confidenceScore: confidenceScore,
        userReasoning: userReasoning,
      );
      await _repo.submitUserPrediction(prediction);
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
      await _fetchMine(state.userId);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
    }
  }

  Future<void> refresh() => _fetchAll(state.userId);
}

final userPredictionsProvider =
    NotifierProvider<UserPredictionsNotifier, UserPredictionsState>(
  UserPredictionsNotifier.new,
);
