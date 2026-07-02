import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../end_points.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ticker model  (market:miniTicker payload)
// ─────────────────────────────────────────────────────────────────────────────

class TickerUpdate {
  final String symbol;
  final double close;
  final double open;
  final double high;
  final double low;
  final double baseVolume;
  final double quoteVolume;

  const TickerUpdate({
    required this.symbol,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.baseVolume,
    required this.quoteVolume,
  });

  double get priceChangePercent => open > 0 ? ((close - open) / open) * 100 : 0;

  factory TickerUpdate.fromJson(Map<String, dynamic> j) => TickerUpdate(
        symbol: j['symbol']?.toString() ?? '',
        close: (j['close'] as num?)?.toDouble() ?? 0,
        open: (j['open'] as num?)?.toDouble() ?? 0,
        high: (j['high'] as num?)?.toDouble() ?? 0,
        low: (j['low'] as num?)?.toDouble() ?? 0,
        baseVolume: (j['baseVolume'] as num?)?.toDouble() ?? 0,
        quoteVolume: (j['quoteVolume'] as num?)?.toDouble() ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LiveWhaleAlert  (dashboard:snapshot → whaleAlerts)
// ─────────────────────────────────────────────────────────────────────────────

class LiveWhaleAlert {
  final String symbol;
  final double amount;
  final double amountUsd;
  final String from;
  final String to;
  final DateTime timestamp;

  const LiveWhaleAlert({
    required this.symbol,
    required this.amount,
    required this.amountUsd,
    required this.from,
    required this.to,
    required this.timestamp,
  });

  static const _exchangeNames = {
    'binance',
    'coinbase',
    'kraken',
    'okx',
    'bybit',
    'huobi',
    'kucoin',
    'bitfinex',
    'bitmex',
    'gate',
  };

  bool get toExchange => _exchangeNames.contains(to.toLowerCase());

  String get formattedAmount {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(2);
  }

  String get formattedUsd {
    if (amountUsd >= 1e9) return '\$${(amountUsd / 1e9).toStringAsFixed(1)}B';
    if (amountUsd >= 1e6) return '\$${(amountUsd / 1e6).toStringAsFixed(0)}M';
    return '\$${amountUsd.toStringAsFixed(0)}';
  }

  String get emoji {
    final s = symbol.toUpperCase();
    if (s == 'BTC') return '🐋';
    if (s == 'ETH') return '💎';
    if (s.contains('USD') || s.contains('USDC')) return '🏦';
    return '🐳';
  }

  factory LiveWhaleAlert.fromJson(Map<String, dynamic> json) {
    String parseName(dynamic val) {
      if (val is Map) return val['name']?.toString() ?? 'Unknown';
      return val?.toString() ?? 'Unknown';
    }

    final tsRaw = json['timestamp'] as num?;
    final ts = tsRaw != null
        ? (tsRaw > 1e12
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt())
            : DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt() * 1000))
        : DateTime.now();

    return LiveWhaleAlert(
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      amountUsd:
          (json['amount_usd'] ?? json['amountUsd'] as num?)?.toDouble() ?? 0,
      from: parseName(json['from']),
      to: parseName(json['to']),
      timestamp: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LiveFundingRate  (dashboard:snapshot → fundingRates)
// ─────────────────────────────────────────────────────────────────────────────

class LiveFundingRate {
  final String symbol;
  final double rate;

  const LiveFundingRate({required this.symbol, required this.rate});

  bool get positive => rate >= 0;
  String get formatted =>
      '${positive ? '+' : ''}${(rate * 100).toStringAsFixed(3)}%';
  bool get isHigh => rate.abs() > 0.0004;

  String get interpretation {
    if (rate < 0) return 'Shorts paying longs — bearish bias';
    if (rate.abs() < 0.0001) return 'Neutral — balanced positioning';
    if (rate.abs() < 0.0002) return 'Moderate long dominance';
    if (rate.abs() < 0.0004) return 'High bullish sentiment';
    return 'Very high — potential squeeze risk';
  }

  factory LiveFundingRate.fromJson(Map<String, dynamic> json) {
    final raw = json['fundingRate'] ?? json['funding_rate'] ?? 0;
    return LiveFundingRate(
      symbol: json['symbol']?.toString() ?? '',
      rate: double.tryParse(raw.toString()) ?? (raw as num?)?.toDouble() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MarketTradeUpdate  (market:trade payload)
// ─────────────────────────────────────────────────────────────────────────────

class MarketTradeUpdate {
  final String symbol;
  final double price;
  final double quantity;
  final bool isBuyerMaker;
  final DateTime time;

  const MarketTradeUpdate({
    required this.symbol,
    required this.price,
    required this.quantity,
    required this.isBuyerMaker,
    required this.time,
  });

  bool get isSell => isBuyerMaker;
  bool get isBuy => !isBuyerMaker;

  String get formattedPrice {
    if (price >= 1000) return price.toStringAsFixed(1);
    if (price >= 1) return price.toStringAsFixed(2);
    return price.toStringAsFixed(4);
  }

  String get formattedQty => quantity.toStringAsFixed(4);

  factory MarketTradeUpdate.fromJson(Map<String, dynamic> j) {
    final tsRaw = j['time'] ?? j['timestamp'] ?? j['T'];
    DateTime ts;
    if (tsRaw is num) {
      ts = tsRaw > 1e12
          ? DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt())
          : DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt() * 1000);
    } else {
      ts = DateTime.now();
    }
    return MarketTradeUpdate(
      symbol: (j['symbol'] ?? j['s'])?.toString() ?? '',
      price: (j['price'] ?? j['p'] as num?)?.toDouble() ??
          double.tryParse((j['price'] ?? j['p'])?.toString() ?? '') ??
          0,
      quantity: (j['quantity'] ?? j['qty'] ?? j['q'] as num?)?.toDouble() ??
          double.tryParse(
              (j['quantity'] ?? j['qty'] ?? j['q'])?.toString() ?? '') ??
          0,
      isBuyerMaker: j['isBuyerMaker'] ?? j['m'] ?? false,
      time: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KlineUpdate  (market:kline payload)
// ─────────────────────────────────────────────────────────────────────────────

class KlineUpdate {
  final String symbol;
  final String interval;
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final bool isClosed;

  const KlineUpdate({
    required this.symbol,
    required this.interval,
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.isClosed,
  });

  factory KlineUpdate.fromJson(Map<String, dynamic> j) {
    final rawOpenTime = (j['openTime'] as num?)?.toInt() ?? 0;
    // normalise to milliseconds (server might send seconds)
    final openTimeMs = rawOpenTime > 0 && rawOpenTime < 1e12.toInt()
        ? rawOpenTime * 1000
        : rawOpenTime;
    return KlineUpdate(
      symbol: (j['symbol']?.toString() ?? '').toUpperCase(),
      interval: (j['interval']?.toString() ?? '').toLowerCase(),
      openTime: openTimeMs,
      open: (j['open'] as num?)?.toDouble() ?? 0,
      high: (j['high'] as num?)?.toDouble() ?? 0,
      low: (j['low'] as num?)?.toDouble() ?? 0,
      close: (j['close'] as num?)?.toDouble() ?? 0,
      volume: (j['volume'] as num?)?.toDouble() ?? 0,
      isClosed: j['isClosed'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OiCandle  (coin:history → oiHistory[])
// ─────────────────────────────────────────────────────────────────────────────

class OiCandle {
  final DateTime time;
  final double openInterest;
  final double openInterestValue;

  const OiCandle({
    required this.time,
    required this.openInterest,
    required this.openInterestValue,
  });

  factory OiCandle.fromJson(Map<String, dynamic> j) {
    final tsRaw = j['timestamp'] as num?;
    final ts = tsRaw != null
        ? DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt())
        : DateTime.now();
    return OiCandle(
      time: ts,
      openInterest:
          double.tryParse(j['sumOpenInterest']?.toString() ?? '') ?? 0,
      openInterestValue:
          double.tryParse(j['sumOpenInterestValue']?.toString() ?? '') ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CoinHistoryData  (coin:history response)
// ─────────────────────────────────────────────────────────────────────────────

class CoinHistoryData {
  final String symbol;
  final double fundingRate;
  final List<OiCandle> oiHistory;

  const CoinHistoryData({
    required this.symbol,
    required this.fundingRate,
    required this.oiHistory,
  });

  bool get fundingPositive => fundingRate >= 0;

  String get formattedFunding =>
      '${fundingPositive ? '+' : ''}${(fundingRate * 100).toStringAsFixed(4)}%';

  String get fundingLevel {
    final abs = fundingRate.abs();
    if (abs > 0.001) return 'Very High';
    if (abs > 0.0004) return 'High';
    if (abs > 0.0002) return 'Elevated';
    if (abs > 0.0001) return 'Moderate';
    return 'Neutral';
  }

  factory CoinHistoryData.fromJson(Map<String, dynamic> j) => CoinHistoryData(
        symbol: j['symbol']?.toString() ?? '',
        fundingRate: double.tryParse(j['fundingRate']?.toString() ?? '') ?? 0,
        oiHistory: (j['oiHistory'] as List?)
                ?.whereType<Map>()
                .map((e) => OiCandle.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LiquidationEvent  (coin:liquidations → recentEvents[])
// ─────────────────────────────────────────────────────────────────────────────

class LiquidationEvent {
  final String symbol;
  final double price;
  final double quantity;
  final String side;
  final DateTime time;

  const LiquidationEvent({
    required this.symbol,
    required this.price,
    required this.quantity,
    required this.side,
    required this.time,
  });

  bool get isLongLiq => side.toUpperCase() == 'SELL';

  String get formattedPrice {
    if (price >= 1000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(5)}';
  }

  factory LiquidationEvent.fromJson(Map<String, dynamic> j) {
    final tsRaw = j['time'] ?? j['T'] ?? j['timestamp'];
    DateTime ts;
    if (tsRaw is num) {
      ts = tsRaw > 1e12
          ? DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt())
          : DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt() * 1000);
    } else {
      ts = DateTime.now();
    }
    return LiquidationEvent(
      symbol: (j['symbol'] ?? j['s'])?.toString() ?? '',
      price: double.tryParse(
              (j['price'] ?? j['p'] ?? j['ap'])?.toString() ?? '') ??
          0,
      quantity:
          double.tryParse((j['origQty'] ?? j['q'])?.toString() ?? '') ?? 0,
      side: (j['side'] ?? j['S'])?.toString() ?? '',
      time: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CoinLiquidationData  (coin:liquidations response)
// ─────────────────────────────────────────────────────────────────────────────

class CoinLiquidationData {
  final String symbol;
  final int count;
  final double longsRektUsd;
  final double shortsRektUsd;
  final List<LiquidationEvent> recentEvents;

  const CoinLiquidationData({
    required this.symbol,
    required this.count,
    required this.longsRektUsd,
    required this.shortsRektUsd,
    required this.recentEvents,
  });

  bool get isEmpty => count == 0;

  String formatUsd(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  factory CoinLiquidationData.fromJson(Map<String, dynamic> j) =>
      CoinLiquidationData(
        symbol: j['symbol']?.toString() ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        longsRektUsd: (j['longsRektUsd'] as num?)?.toDouble() ?? 0,
        shortsRektUsd: (j['shortsRektUsd'] as num?)?.toDouble() ?? 0,
        recentEvents: (j['recentEvents'] as List?)
                ?.whereType<Map>()
                .map((e) =>
                    LiquidationEvent.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardSocket  — Socket.IO client for live dashboard data
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSocket {
  DashboardSocket._();
  static final DashboardSocket instance = DashboardSocket._();

  sio.Socket? _socket;
  String? _activeChartSymbol;
  String _activeInterval = '1m';

  // ── Broadcast streams — widgets subscribe to these ────────────────────────
  final _tickerCtrl = StreamController<List<TickerUpdate>>.broadcast();
  final _snapshotCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _whaleCtrl = StreamController<List<LiveWhaleAlert>>.broadcast();
  final _fundingCtrl = StreamController<List<LiveFundingRate>>.broadcast();
  final _klineCtrl = StreamController<KlineUpdate>.broadcast();
  final _tradeCtrl = StreamController<MarketTradeUpdate>.broadcast();
  final _connectionCtrl = StreamController<bool>.broadcast();
  final _coinHistoryCtrl = StreamController<CoinHistoryData>.broadcast();
  final _coinLiquidationsCtrl =
      StreamController<CoinLiquidationData>.broadcast();

  Stream<List<TickerUpdate>> get tickerStream => _tickerCtrl.stream;
  Stream<Map<String, dynamic>> get snapshotStream => _snapshotCtrl.stream;
  Stream<List<LiveWhaleAlert>> get whaleStream => _whaleCtrl.stream;
  Stream<List<LiveFundingRate>> get fundingStream => _fundingCtrl.stream;
  Stream<KlineUpdate> get klineStream => _klineCtrl.stream;
  Stream<MarketTradeUpdate> get tradeStream => _tradeCtrl.stream;
  Stream<bool> get connectionStream => _connectionCtrl.stream;
  Stream<CoinHistoryData> get coinHistoryStream => _coinHistoryCtrl.stream;
  Stream<CoinLiquidationData> get coinLiquidationsStream =>
      _coinLiquidationsCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return; // already connecting / connected

    print(
        '[DashboardSocket] Connecting to ${EndPoints.socketUrl} with path ${EndPoints.socketPath}');

    _socket = sio.io(
      EndPoints.socketUrl,
      sio.OptionBuilder()
          .setPath(EndPoints.socketPath)
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        print('[DashboardSocket] connected successfully');
        _connectionCtrl.add(true);
        _subscribe();
      })
      ..on('socket:connected', (data) {
        print('[DashboardSocket] server ready: $data');
      })
      ..on('dashboard:snapshot', (data) {
        print('[DashboardSocket] received snapshot payload');
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          _snapshotCtrl.add(map);
          _parseSnapshot(map);
        } else {
          print(
              '[DashboardSocket] warning: snapshot payload is not a Map: $data');
        }
      })
      ..on('market:miniTicker', (data) {
        if (data is List) {
          final tickers = data
              .where((item) => item is Map)
              .map((item) =>
                  TickerUpdate.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          if (tickers.isNotEmpty) {
            _tickerCtrl.add(tickers);
          }
        }
      })
      ..on('market:kline', (data) {
        print('[DashboardSocket] received kline tick: $data');
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          _klineCtrl.add(KlineUpdate.fromJson(map));
        } else {
          print('[DashboardSocket] warning: kline payload is not a Map: $data');
        }
      })
      ..on('market:trade', (data) {
        if (data is Map) {
          _tradeCtrl
              .add(MarketTradeUpdate.fromJson(Map<String, dynamic>.from(data)));
        } else if (data is List) {
          for (final item in data) {
            if (item is Map) {
              _tradeCtrl.add(MarketTradeUpdate.fromJson(
                  Map<String, dynamic>.from(item as Map)));
            }
          }
        }
      })
      ..on('coin:history', (data) {
        if (data is Map) {
          _coinHistoryCtrl
              .add(CoinHistoryData.fromJson(Map<String, dynamic>.from(data)));
        }
      })
      ..on('coin:liquidations', (data) {
        if (data is Map) {
          _coinLiquidationsCtrl.add(
              CoinLiquidationData.fromJson(Map<String, dynamic>.from(data)));
        }
      })
      ..onDisconnect((_) {
        print('[DashboardSocket] disconnected');
        _connectionCtrl.add(false);
      })
      ..onError((e) => print('[DashboardSocket] error: $e'))
      ..connect();
  }

  void reconnect() {
    disconnect();
    connect();
  }

  void _subscribe() {
    final Set<String> allSymbols = {
      'BTCUSDT',
      'ETHUSDT',
      'SOLUSDT',
      'BNBUSDT',
      'XRPUSDT',
      'DOGEUSDT'
    };
    if (_activeChartSymbol != null && _activeChartSymbol!.isNotEmpty) {
      allSymbols.add(_activeChartSymbol!.toUpperCase());
    }

    print(
        '[DashboardSocket] Emitting subscribe for symbols: ${allSymbols.toList()} with interval $_activeInterval');
    _socket?.emit('dashboard:subscribe', {
      'symbols': allSymbols.toList(),
      'klineInterval': _activeInterval,
      'includeSnapshot': true,
      'includeWhales': true,
      'includeFunding': true,
      'includeTrades': true,
    });
  }

  void subscribeWithInterval(String symbol, String interval) {
    _activeChartSymbol = symbol;
    _activeInterval = interval;
    _subscribe();
  }

  void requestCoinHistory(String symbol) {
    final sym = symbol.toUpperCase().endsWith('USDT')
        ? symbol.toUpperCase()
        : '${symbol.toUpperCase()}USDT';
    _socket?.emit('coin:getHistory', {'symbol': sym});
  }

  void requestCoinLiquidations(String symbol) {
    final sym = symbol.toUpperCase().endsWith('USDT')
        ? symbol.toUpperCase()
        : '${symbol.toUpperCase()}USDT';
    _socket?.emit('coin:getLiquidations', {'symbol': sym});
  }

  void _parseSnapshot(Map<String, dynamic> data) {
    try {
      if (data.containsKey('whaleAlerts') && data['whaleAlerts'] is List) {
        final list = data['whaleAlerts'] as List;
        final alerts = list
            .where((item) => item is Map)
            .map((item) =>
                LiveWhaleAlert.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _whaleCtrl.add(alerts);
      }
      if (data.containsKey('fundingRates') && data['fundingRates'] is List) {
        final list = data['fundingRates'] as List;
        final rates = list
            .where((item) => item is Map)
            .map((item) => LiveFundingRate.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        _fundingCtrl.add(rates);
      }
    } catch (e, stack) {
      print('[DashboardSocket] Error parsing snapshot: $e\n$stack');
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _tickerCtrl.close();
    _snapshotCtrl.close();
    _whaleCtrl.close();
    _fundingCtrl.close();
    _klineCtrl.close();
    _tradeCtrl.close();
    _connectionCtrl.close();
    _coinHistoryCtrl.close();
    _coinLiquidationsCtrl.close();
  }
}
