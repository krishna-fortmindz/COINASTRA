import '../../api_client.dart';
import '../../../end_points.dart';
import 'predictions_repo.dart';
import 'models/predictions_models.dart';

class PredictionsRepoImpl implements PredictionsRepo {
  final _api = ApiClient.instance;

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = raw['items'] as List? ??
          raw['data'] as List? ??
          raw['results'] as List? ??
          [];
    }
    return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    final data = raw?['data'];
    if (data is Map<String, dynamic>) return data;
    return raw ?? {};
  }

  List<LeaderboardEntry> _parseLeaderboard(dynamic raw, {int page = 1, int limit = 10}) {
    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      for (final key in ['rankings', 'leaderboard', 'entries', 'items', 'results', 'coins']) {
        if (raw[key] is List) { list = raw[key] as List; break; }
      }
    }
    final maps = list.whereType<Map<String, dynamic>>().toList();
    final offset = (page - 1) * limit;
    return maps
        .asMap()
        .entries
        .map((e) => LeaderboardEntry.fromJson(e.value, rankOverride: offset + e.key + 1))
        .toList();
  }

  int _parseTotalPages(Map<String, dynamic> body, int total, int limit) {
    final pagination = body['pagination'] as Map<String, dynamic>?;
    final tp = (pagination?['totalPages'] as num?)?.toInt() ??
        (body['totalPages'] as num?)?.toInt() ??
        (body['pages'] as num?)?.toInt();
    if (tp != null) return tp;
    if (total > 0 && limit > 0) return (total + limit - 1) ~/ limit;
    return 1;
  }

  @override
  Future<LeaderboardPage> fetchLeaderboard({
    String timeframe = '30d',
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionsLeaderboard,
      queryParams: {'timeframe': timeframe, 'limit': limit, 'page': page},
    );
    final body = res.data ?? {};
    final rawData = body['data'] ?? body;

    final pagination = (rawData is Map ? rawData['pagination'] : null)
        as Map<String, dynamic>? ?? {};
    final total = (pagination['total'] as num?)?.toInt() ??
        (body['total'] as num?)?.toInt() ??
        (body['count'] as num?)?.toInt() ?? 0;
    final totalPages = _parseTotalPages(body, total, limit);

    final entries = _parseLeaderboard(rawData, page: page, limit: limit);
    return LeaderboardPage(
      entries: entries,
      page: page,
      totalPages: totalPages,
      total: total,
      limit: limit,
    );
  }

  @override
  Future<CoinAccuracy> fetchAccuracy(String coinId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionAccuracy(coinId),
      queryParams: {'timeframe': 'all'},
    );
    return CoinAccuracy.fromJson(_unwrap(res.data));
  }

  @override
  Future<List<PredictionRecord>> fetchHistory(String coinId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionHistory(coinId),
    );
    return _parseList(res.data?['data'], PredictionRecord.fromJson);
  }

  @override
  Future<List<PostMortem>> fetchPostMortems(String coinId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionPostMortems(coinId),
    );
    return _parseList(res.data?['data'], PostMortem.fromJson);
  }

  @override
  Future<void> submitUserPrediction(UserPrediction prediction) async {
    await _api.post<Map<String, dynamic>>(
      EndPoints.predictionsUser,
      data: prediction.toJson(),
    );
  }

  @override
  Future<List<PredictionRecord>> fetchUserMine(String userId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionsUserMine,
      queryParams: {'userId': userId},
    );
    return _parseList(res.data?['data'], PredictionRecord.fromJson);
  }

  @override
  Future<UserVsAi> fetchUserVsAi(String userId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.predictionsUserVsAi,
      queryParams: {'userId': userId},
    );
    return UserVsAi.fromJson(_unwrap(res.data));
  }
}
