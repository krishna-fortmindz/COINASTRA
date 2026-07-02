import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/core/remote/api_client.dart';
import 'analysis_repo.dart';
import 'analysis_models.dart';

class AnalysisRepoImpl implements AnalysisRepo {
  final _api = ApiClient.instance;

  @override
  Future<AiAnalysis> fetchMarketAnalysis() => _api.fetchModel(
        EndPoints.analysisSignal,
        AiAnalysis.fromSignalJson,
        queryParams: {'symbol': 'BTCUSDT'},
      );

  @override
  Future<AiAnalysis> fetchCoinAnalysis(String coinId) =>
      _api.fetchModel(EndPoints.coinAiAnalysis(coinId), AiAnalysis.fromJson);
}
