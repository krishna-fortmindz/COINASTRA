import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/analysis/analysis_repo_impl.dart';
import '../core/remote/data/analysis/analysis_models.dart';

final _repo = AnalysisRepoImpl();

final marketAiProvider = FutureProvider<AiAnalysis>((ref) {
  return _repo.fetchMarketAnalysis();
});

final coinAiProvider = FutureProvider.family<AiAnalysis, String>((ref, coinId) {
  return _repo.fetchCoinAnalysis(coinId);
});
