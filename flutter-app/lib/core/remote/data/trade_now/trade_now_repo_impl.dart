import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/core/remote/api_client.dart';
import 'trade_now_repo.dart';
import 'models/trade_now_models.dart';

class TradeNowRepoImpl implements TradeNowRepo {
  final _api = ApiClient.instance;

  @override
  Future<SignalData> fetchSignal(String symbol) => _api.fetchModel(
        EndPoints.analysisSignal,
        SignalData.fromJson,
        queryParams: {'symbol': '${symbol}USDT'},
      );

  @override
  Future<SentimentData> fetchSentiment(String symbol) => _api.fetchModel(
        EndPoints.analysisSentiment,
        SentimentData.fromJson,
        queryParams: {'symbol': '${symbol}USDT'},
      );

  @override
  Future<OpenInterestData> fetchOpenInterest(String symbol) => _api.fetchModel(
        EndPoints.analysisOpenInterest,
        OpenInterestData.fromJson,
        queryParams: {'symbol': '${symbol}USDT'},
      );

  @override
  Future<LongShortData> fetchLongShort(String symbol) => _api.fetchModel(
        EndPoints.analysisLongShort,
        LongShortData.fromJson,
        queryParams: {'symbol': '${symbol}USDT'},
      );

  @override
  Future<LiquidationData> fetchLiquidations(String symbol) => _api.fetchModel(
        EndPoints.analysisLiquidations,
        LiquidationData.fromJson,
        queryParams: {'symbol': '${symbol}USDT'},
      );

  @override
  Future<FundingRateInfo> fetchFundingRate(String symbol) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.fundingRates,
      queryParams: {'symbols': '${symbol}USDT'},
    );
    final raw = res.data ?? {};
    final list = raw['data'] as List? ?? [];
    if (list.isEmpty) return FundingRateInfo.empty;
    return FundingRateInfo.fromJson(
      list.first as Map<String, dynamic>,
    );
  }

  @override
  Future<List<HistoricalSetup>> fetchHistory(String symbol,
      {int limit = 5}) async {
    // API returns { success, data: { symbol, examples: [...], ... } }
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.analysisHistory,
      queryParams: {'symbol': '${symbol}USDT', 'limit': '$limit'},
    );
    final raw = res.data ?? {};
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final list = data['examples'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(HistoricalSetup.fromJson).toList();
  }
}