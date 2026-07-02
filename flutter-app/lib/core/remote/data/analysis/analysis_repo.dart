import 'analysis_models.dart';

abstract class AnalysisRepo {
  Future<AiAnalysis> fetchMarketAnalysis();
  Future<AiAnalysis> fetchCoinAnalysis(String coinId);
}
