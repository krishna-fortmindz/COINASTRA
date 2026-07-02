import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/orderbook/orderbook_repo_impl.dart';
import '../core/remote/data/orderbook/models/orderbook_models.dart';
import '../core/remote/web_socket_baseclass.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class OrderBookState {
  final String symbol;
  final AsyncValue<OrderBookData> orderBook;
  final AsyncValue<Ticker24hrData> ticker;
  final AsyncValue<List<KeyLevelData>> keyLevels;
  final List<MarketTradeUpdate> recentTrades;

  const OrderBookState({
    required this.symbol,
    required this.orderBook,
    required this.ticker,
    required this.keyLevels,
    required this.recentTrades,
  });

  static OrderBookState loading(String symbol) => OrderBookState(
        symbol: symbol,
        orderBook: const AsyncValue.loading(),
        ticker: const AsyncValue.loading(),
        keyLevels: const AsyncValue.loading(),
        recentTrades: const [],
      );

  OrderBookState copyWith({
    String? symbol,
    AsyncValue<OrderBookData>? orderBook,
    AsyncValue<Ticker24hrData>? ticker,
    AsyncValue<List<KeyLevelData>>? keyLevels,
    List<MarketTradeUpdate>? recentTrades,
  }) =>
      OrderBookState(
        symbol: symbol ?? this.symbol,
        orderBook: orderBook ?? this.orderBook,
        ticker: ticker ?? this.ticker,
        keyLevels: keyLevels ?? this.keyLevels,
        recentTrades: recentTrades ?? this.recentTrades,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OrderBookNotifier extends Notifier<OrderBookState> {
  final _repo = OrderBookRepoImpl();

  StreamSubscription<MarketTradeUpdate>? _tradeSub;
  StreamSubscription<List<TickerUpdate>>? _tickerSub;
  Timer? _refreshTimer;

  @override
  OrderBookState build() {
    ref.onDispose(_dispose);
    _startLiveUpdates();
    _fetchAll('BTCUSDT');
    return OrderBookState.loading('BTCUSDT');
  }

  void selectCoin(String coin) {
    final symbol = '${coin.toUpperCase()}USDT';
    state = OrderBookState.loading(symbol);
    _fetchAll(symbol);
  }

  Future<void> refresh() => _fetchAll(state.symbol);

  void _dispose() {
    _tradeSub?.cancel();
    _tickerSub?.cancel();
    _refreshTimer?.cancel();
  }

  // ── Live updates ────────────────────────────────────────────────────────────

  void _startLiveUpdates() {
    final socket = DashboardSocket.instance;
    socket.connect();

    // market:trade → feed recent trades list
    _tradeSub = socket.tradeStream.listen((trade) {
      if (trade.symbol == state.symbol) {
        final updated = [trade, ...state.recentTrades].take(30).toList();
        state = state.copyWith(recentTrades: updated);
      }
    });

    // market:miniTicker → update last price on the existing ticker in real-time
    _tickerSub = socket.tickerStream.listen((tickers) {
      final match = tickers.cast<TickerUpdate?>().firstWhere(
            (t) => t?.symbol == state.symbol,
            orElse: () => null,
          );
      if (match == null) return;

      final current = state.ticker.valueOrNull;
      if (current == null) return;

      state = state.copyWith(
        ticker: AsyncValue.data(
          Ticker24hrData(
            symbol: current.symbol,
            lastPrice: match.close,
            bestBid: current.bestBid,
            bestAsk: current.bestAsk,
            priceChange: current.priceChange,
            priceChangePercent: current.priceChangePercent,
            volume: match.baseVolume,
            high: match.high,
            low: match.low,
          ),
        ),
      );
    });

    // Refresh order book bids/asks every 5 seconds (no socket event for full book)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchOrderBook(state.symbol);
    });
  }

  // ── REST fetches ────────────────────────────────────────────────────────────

  Future<void> _fetchAll(String symbol) {
    return Future.wait([
      _fetchOrderBook(symbol),
      _fetchTicker(symbol),
      _fetchKeyLevels(symbol),
    ]);
  }

  Future<void> _fetchOrderBook(String symbol) async {
    try {
      final data = await _repo.fetchOrderBook(symbol, limit: 20);
      if (state.symbol == symbol) {
        state = state.copyWith(orderBook: AsyncValue.data(data));
      }
    } catch (e, st) {
      if (state.symbol == symbol && state.orderBook.isLoading) {
        state = state.copyWith(orderBook: AsyncValue.error(e, st));
      }
    }
  }

  Future<void> _fetchTicker(String symbol) async {
    try {
      final data = await _repo.fetchTicker24hr(symbol);
      if (state.symbol == symbol) {
        state = state.copyWith(ticker: AsyncValue.data(data));
      }
    } catch (e, st) {
      if (state.symbol == symbol) {
        state = state.copyWith(ticker: AsyncValue.error(e, st));
      }
    }
  }

  Future<void> _fetchKeyLevels(String symbol) async {
    try {
      final data = await _repo.fetchKeyLevels(symbol);
      if (state.symbol == symbol) {
        state = state.copyWith(keyLevels: AsyncValue.data(data));
      }
    } catch (e, st) {
      if (state.symbol == symbol) {
        state = state.copyWith(keyLevels: AsyncValue.error(e, st));
      }
    }
  }
}

final orderBookProvider =
    NotifierProvider<OrderBookNotifier, OrderBookState>(OrderBookNotifier.new);
