import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/web_socket_baseclass.dart';

// ── Coin History (Funding Rate + OI) ─────────────────────────────────────────

class CoinHistoryNotifier
    extends StateNotifier<AsyncValue<CoinHistoryData>> {
  CoinHistoryNotifier(this._symbol) : super(const AsyncValue.loading()) {
    final socket = DashboardSocket.instance;
    _dataSub = socket.coinHistoryStream
        .where((d) => d.symbol.toUpperCase() == _symbol.toUpperCase())
        .listen((data) {
      if (mounted) state = AsyncValue.data(data);
    });
    if (socket.isConnected) {
      socket.requestCoinHistory(_symbol);
    } else {
      _connSub = socket.connectionStream.listen((connected) {
        if (connected) {
          socket.requestCoinHistory(_symbol);
          _connSub?.cancel();
          _connSub = null;
        }
      });
    }
  }

  final String _symbol;
  StreamSubscription<CoinHistoryData>? _dataSub;
  StreamSubscription<bool>? _connSub;

  void refresh() {
    state = const AsyncValue.loading();
    DashboardSocket.instance.requestCoinHistory(_symbol);
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

final coinHistoryProvider = StateNotifierProvider.family<CoinHistoryNotifier,
    AsyncValue<CoinHistoryData>, String>(
  (ref, symbol) => CoinHistoryNotifier(symbol),
);

// ── Coin Liquidations ─────────────────────────────────────────────────────────

class CoinLiquidationsNotifier
    extends StateNotifier<AsyncValue<CoinLiquidationData>> {
  CoinLiquidationsNotifier(this._symbol) : super(const AsyncValue.loading()) {
    final socket = DashboardSocket.instance;
    _dataSub = socket.coinLiquidationsStream
        .where((d) => d.symbol.toUpperCase() == _symbol.toUpperCase())
        .listen((data) {
      if (mounted) state = AsyncValue.data(data);
    });
    if (socket.isConnected) {
      socket.requestCoinLiquidations(_symbol);
    } else {
      _connSub = socket.connectionStream.listen((connected) {
        if (connected) {
          socket.requestCoinLiquidations(_symbol);
          _connSub?.cancel();
          _connSub = null;
        }
      });
    }
  }

  final String _symbol;
  StreamSubscription<CoinLiquidationData>? _dataSub;
  StreamSubscription<bool>? _connSub;

  void refresh() {
    state = const AsyncValue.loading();
    DashboardSocket.instance.requestCoinLiquidations(_symbol);
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

final coinLiquidationsProvider = StateNotifierProvider.family<
    CoinLiquidationsNotifier, AsyncValue<CoinLiquidationData>, String>(
  (ref, symbol) => CoinLiquidationsNotifier(symbol),
);
