import 'models/trade_now_models.dart';

abstract class TradeNowRepo {
  Future<SignalData> fetchSignal(String symbol);
  Future<SentimentData> fetchSentiment(String symbol);
  Future<OpenInterestData> fetchOpenInterest(String symbol);
  Future<LongShortData> fetchLongShort(String symbol);

  Future<LiquidationData> fetchLiquidations(String symbol);
  Future<FundingRateInfo> fetchFundingRate(String symbol);
  Future<List<HistoricalSetup>> fetchHistory(String symbol, {int limit = 5});
}
