import 'models/new_listings_models.dart';

abstract class NewListingsRepo {
  Future<List<NewListing>> fetchListings({
    String? category,
    int page = 1,
    int limit = 20,
  });

  Future<AiListingScore> fetchAiScore(String coinId);
}
