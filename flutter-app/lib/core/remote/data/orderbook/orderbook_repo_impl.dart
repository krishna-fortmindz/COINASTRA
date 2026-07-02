import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/core/remote/api_client.dart';
import 'orderbook_repo.dart';
import 'models/orderbook_models.dart';

class OrderBookRepoImpl implements OrderBookRepo {
  final _api = ApiClient.instance;

  @override
  Future<OrderBookData> fetchOrderBook(String symbol, {int limit = 20}) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.orderBook,
      queryParams: {'symbol': symbol, 'limit': '$limit'},
    );
    final raw = res.data ?? {};
    final inner = raw['data'] as Map<String, dynamic>? ?? raw;
    return OrderBookData.fromJson(inner);
  }

  @override
  Future<Ticker24hrData> fetchTicker24hr(String symbol) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.ticker24hr,
      queryParams: {'symbol': symbol},
    );
    final raw = res.data ?? {};
    final inner = raw['data'] as Map<String, dynamic>? ?? raw;
    return Ticker24hrData.fromJson(inner);
  }

  @override
  Future<List<KeyLevelData>> fetchKeyLevels(String symbol) async {
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.analysisLevels,
      queryParams: {'symbol': symbol},
    );
    final raw = res.data ?? {};
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    final list = data['levels'] as List? ?? data['data'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(KeyLevelData.fromJson)
        .toList();
  }
}
