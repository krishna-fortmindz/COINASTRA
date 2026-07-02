import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/core/remote/api_client.dart';
import 'dashboard_repo.dart';
import 'models/dashboard_models.dart';

class DashboardRepoImpl implements DashboardRepo {
  final _api = ApiClient.instance;

  @override
  Future<DashboardSummary> fetchSummary() => _api.fetchModel(
        EndPoints.dashboardSummary,
        DashboardSummary.fromJson,
        queryParams: const {
          'coinIds': 'bitcoin,ethereum,solana,binancecoin',
          'symbols': 'BTCUSDT,ETHUSDT,SOLUSDT,BNBUSDT',
        },
      );

  @override
  Future<List<MarketCoin>> fetchMarketCoins() => _api.fetchList(
        EndPoints.marketCoins,
        MarketCoin.fromJson,
        queryParams: const {
          'coinIds': 'bitcoin,ethereum,solana,binancecoin,ripple,dogecoin',
          'sparkline': 'true',
        },
      );

  @override
  Future<List<MarketCoin>> searchMarketCoins(String query,
          {int perPage = 10}) =>
      _api.fetchList(
        EndPoints.marketCoinsSearch(searchQuery: query, perPage: perPage),
        MarketCoin.fromJson,
      );

  @override
  Future<FearGreedData> fetchFearGreed() async {
    // Fear & Greed can arrive as { data: [{value, value_classification}] }
    // (Alternative.me) or as { value, classification } (flat backend).
    // fetchModel unwraps a Map data envelope; pass the full raw response to
    // FearGreedData.fromJson so it can handle both shapes itself.
    final res = await _api.get<Map<String, dynamic>>(EndPoints.fearGreedIndex);
    return FearGreedData.fromJson(res.data ?? {});
  }

  @override
  Future<List<TrendingCoin>> fetchTrending() async {
    // Response shape: { success, data: { coins: [ {item: {...}} ] } }
    final res = await _api.get<Map<String, dynamic>>(EndPoints.trendingCoins);
    final raw = res.data ?? {};
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final list = data['coins'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TrendingCoin.fromJson)
        .toList();
  }

  @override
  Future<List<FundingRate>> fetchFundingRates() async {
    final rates = await _api.fetchList(
      EndPoints.fundingRates,
      FundingRate.fromJson,
      queryParams: const {'symbols': 'BTCUSDT,ETHUSDT,SOLUSDT,BNBUSDT,XRPUSDT'},
    );
    const wanted = {'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT', 'XRPUSDT'};
    final filtered = rates.where((r) => wanted.contains(r.symbol)).toList();
    return filtered.isNotEmpty ? filtered : rates.take(5).toList();
  }

  Future<List<FundingRate>> fetchAllFundingRates() async {
    final rates = await _api.fetchList(
      EndPoints.fundingRates,
      FundingRate.fromJson,
      queryParams: const {'limit': '100'},
    );
    return rates;
  }
}
