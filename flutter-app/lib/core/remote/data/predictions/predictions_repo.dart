import 'models/predictions_models.dart';

abstract class PredictionsRepo {
  Future<LeaderboardPage> fetchLeaderboard({String timeframe, int page, int limit});
  Future<CoinAccuracy> fetchAccuracy(String coinId);
  Future<List<PredictionRecord>> fetchHistory(String coinId);
  Future<List<PostMortem>> fetchPostMortems(String coinId);
  Future<void> submitUserPrediction(UserPrediction prediction);
  Future<List<PredictionRecord>> fetchUserMine(String userId);
  Future<UserVsAi> fetchUserVsAi(String userId);
}
