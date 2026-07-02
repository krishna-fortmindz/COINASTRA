import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/dashboard/dashboard_repo_impl.dart';
import '../core/remote/data/dashboard/models/dashboard_models.dart';
import '../core/remote/web_socket_baseclass.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Summary  (coins + fearGreed + trending + whales + ai + funding)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSummaryNotifier extends AsyncNotifier<DashboardSummary> {
  final _repo = DashboardRepoImpl();

  @override
  Future<DashboardSummary> build() => _repo.fetchSummary();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.fetchSummary);
  }
}

final dashboardSummaryProvider =
    AsyncNotifierProvider<DashboardSummaryNotifier, DashboardSummary>(
  DashboardSummaryNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Individual section providers — each hits its own endpoint independently
// ─────────────────────────────────────────────────────────────────────────────

final _repo = DashboardRepoImpl();

final marketCoinsProvider = FutureProvider<List<MarketCoin>>(
  (_) => _repo.fetchMarketCoins(),
);

final fearGreedProvider = FutureProvider<FearGreedData>(
  (_) => _repo.fetchFearGreed(),
);

final trendingProvider = FutureProvider<List<TrendingCoin>>(
  (_) => _repo.fetchTrending(),
);

final fundingRatesProvider = FutureProvider<List<FundingRate>>(
  (_) => _repo.fetchFundingRates(),
);

final allFundingRatesProvider = FutureProvider<List<FundingRate>>(
  (_) => _repo.fetchAllFundingRates(),
);


// Coin search provider — parameterized by query string
final coinSearchProvider =
    FutureProvider.family<List<MarketCoin>, String>((ref, query) {
  return _repo.searchMarketCoins(query, perPage: 10);
});

// ─────────────────────────────────────────────────────────────────────────────
// Live ticker stream  (Socket.IO market:miniTicker)
// Map of symbol → TickerUpdate for O(1) lookup in widgets
// ─────────────────────────────────────────────────────────────────────────────

final tickerProvider = StreamProvider<Map<String, TickerUpdate>>((ref) {
  final socket = DashboardSocket.instance;
  socket.connect();
  ref.onDispose(socket.disconnect);

  return socket.tickerStream.map((list) {
    return {for (final t in list) t.symbol: t};
  });
});

final socketConnectionProvider = StreamProvider<bool>((ref) {
  final socket = DashboardSocket.instance;
  socket.connect();
  return socket.connectionStream;
});

final liveWhaleProvider = StreamProvider<List<LiveWhaleAlert>>((ref) {
  final socket = DashboardSocket.instance;
  socket.connect();
  ref.onDispose(socket.disconnect);
  return socket.whaleStream;
});

final liveFundingProvider = StreamProvider<List<LiveFundingRate>>((ref) {
  final socket = DashboardSocket.instance;
  socket.connect();
  ref.onDispose(socket.disconnect);
  return socket.fundingStream;
});

// Funding rate history for a specific symbol (e.g. 'BTCUSDT')
final fundingHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, symbol) async {
  final res = await ApiClient.instance
      .get<dynamic>(EndPoints.fundingRatesWithSymbol(symbol: symbol, limit: 20));
  final body = res.data;
  List<dynamic> list = const [];
  if (body is List) {
    list = body;
  } else if (body is Map) {
    final inner = body['data'] ?? body['rates'] ?? body['fundingRates'] ?? body['result'];
    if (inner is List) list = inner;
  }
  return list
      .whereType<Map<String, dynamic>>()
      .toList();
});
