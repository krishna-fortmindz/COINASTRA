import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/core/remote/api_client.dart';
import 'new_listings_repo.dart';
import 'models/new_listings_models.dart';

class NewListingsRepoImpl implements NewListingsRepo {
  final _api = ApiClient.instance;

  @override
  Future<List<NewListing>> fetchListings({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'limit': '$limit',
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.newListings,
      queryParams: params,
    );
    final raw = res.data ?? {};
    final data = raw['data'];
    List<dynamic> list = [];
    if (data is Map) {
      list = data['listings'] as List? ??
          data['items'] as List? ??
          data['data'] as List? ??
          [];
    } else if (data is List) {
      list = data;
    }
    return list.whereType<Map<String, dynamic>>().map(NewListing.fromJson).toList();
  }

  @override
  Future<AiListingScore> fetchAiScore(String coinId) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.newListingsAiScore,
      queryParams: {'coinId': coinId},
    );
    final raw = res.data ?? {};
    final inner = raw['data'] as Map<String, dynamic>? ?? raw;
    return AiListingScore.fromJson(inner);
  }
}
