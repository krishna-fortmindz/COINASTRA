import 'models/orderbook_models.dart';

abstract class OrderBookRepo {
  Future<OrderBookData> fetchOrderBook(String symbol, {int limit = 20});
  Future<Ticker24hrData> fetchTicker24hr(String symbol);
  Future<List<KeyLevelData>> fetchKeyLevels(String symbol);
}
