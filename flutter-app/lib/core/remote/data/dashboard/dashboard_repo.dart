import 'models/dashboard_models.dart';

abstract class DashboardRepo {
  Future<DashboardSummary> fetchSummary();
  Future<List<MarketCoin>> fetchMarketCoins();
  Future<List<MarketCoin>> searchMarketCoins(String query, {int perPage = 10});
  Future<FearGreedData> fetchFearGreed();
  Future<List<TrendingCoin>> fetchTrending();
  Future<List<FundingRate>> fetchFundingRates();
}
