import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';
import '../core/remote/data/sentiment/sentiment_models.dart';

// ── Selected coin for coin-signals tab ────────────────────────────────────────

final sentimentCoinIdProvider = StateProvider<String>((ref) => 'bitcoin');

// ── News pagination state ─────────────────────────────────────────────────────

class SentimentNewsState {
  final List<SentimentNewsItem> items;
  final bool isLoading;
  final int page;
  final int? totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? error;

  const SentimentNewsState({
    this.items = const [],
    this.isLoading = false,
    this.page = 1,
    this.totalPages,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.error,
  });

  SentimentNewsState copyWith({
    List<SentimentNewsItem>? items,
    bool? isLoading,
    int? page,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? error,
  }) =>
      SentimentNewsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
        error: error,
      );
}

class SentimentNewsNotifier extends StateNotifier<SentimentNewsState> {
  static const _limit = 20;

  SentimentNewsNotifier() : super(const SentimentNewsState(isLoading: true)) {
    _load(1);
  }

  Future<void> _load(int page) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ApiClient.instance;
      final res = await api.get<dynamic>(
        EndPoints.sentimentNewsWithParams(page: page, limit: _limit),
      );

      final (articles, pagination) = _parse(res.data);

      // Prefer server pagination flags; fall back to safe defaults
      final hasNext = pagination?['hasNextPage'] as bool? ?? false;
      final hasPrev = pagination?['hasPrevPage'] as bool? ?? (page > 1);
      final totalPgs = (pagination?['totalPages'] as num?)?.toInt();

      state = state.copyWith(
        items: articles,
        isLoading: false,
        page: page,
        totalPages: totalPgs,
        hasNextPage: hasNext,
        hasPreviousPage: hasPrev,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  static (List<SentimentNewsItem>, Map<String, dynamic>?) _parse(
      dynamic body) {
    List<dynamic> rawList = const [];
    Map<String, dynamic>? pagination;

    if (body is List) {
      rawList = body;
    } else if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        rawList = (data['articles'] ?? data['news'] ?? data['items'] ?? [])
            as List<dynamic>;
        final p = data['pagination'];
        if (p is Map) pagination = Map<String, dynamic>.from(p);
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = (body['articles'] ?? body['news'] ?? body['items'] ?? [])
            as List<dynamic>;
        final p = body['pagination'];
        if (p is Map) pagination = Map<String, dynamic>.from(p);
      }
    }

    final items = rawList
        .whereType<Map>()
        .map((m) => SentimentNewsItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return (items, pagination);
  }

  Future<void> nextPage() async {
    if (state.isLoading || !state.hasNextPage) return;
    await _load(state.page + 1);
  }

  Future<void> previousPage() async {
    if (state.isLoading || !state.hasPreviousPage) return;
    await _load(state.page - 1);
  }

  Future<void> refresh() async => _load(state.page);
}


final sentimentNewsProvider = StateNotifierProvider.autoDispose<
    SentimentNewsNotifier, SentimentNewsState>(
  (ref) => SentimentNewsNotifier(),
);

// ── Social ────────────────────────────────────────────────────────────────────

final sentimentSocialProvider =
    FutureProvider.autoDispose<SocialSentimentData>((ref) async {
  final api = ApiClient.instance;
  final res = await api.get<Map<String, dynamic>>(
    EndPoints.sentimentSocial,
    queryParams: {'symbol': 'BTCUSDT'},
  );
  final raw = res.data ?? {};
  final inner = raw['data'];
  final payload = inner is Map<String, dynamic> ? inner : raw;
  return SocialSentimentData.fromJson(payload);
});

// ── Coin signals ──────────────────────────────────────────────────────────────

final coinSentimentProvider = FutureProvider.autoDispose
    .family<CoinSentimentData, String>((ref, coinId) async {
  final api = ApiClient.instance;
  final res =
      await api.get<Map<String, dynamic>>(EndPoints.sentimentCoin(coinId));
  final raw = res.data ?? {};
  final inner = raw['data'];
  final payload = inner is Map<String, dynamic> ? inner : raw;
  return CoinSentimentData.fromJson(payload);
});

// ── On-Chain ──────────────────────────────────────────────────────────────────

final onChainSentimentProvider =
    FutureProvider.autoDispose<OnChainSentimentData>((ref) async {
  final api = ApiClient.instance;
  final res = await api.get<Map<String, dynamic>>(EndPoints.sentimentOnChain);
  final raw = res.data ?? {};
  final inner = raw['data'];
  final payload = inner is Map<String, dynamic> ? inner : raw;
  return OnChainSentimentData.fromJson(payload);
});
