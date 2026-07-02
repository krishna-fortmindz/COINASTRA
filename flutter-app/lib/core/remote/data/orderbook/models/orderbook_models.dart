// ── OrderBook ─────────────────────────────────────────────────────────────────

class OrderBookLevelWithTotal {
  final double price;
  final double quantity;
  final double total;
  final bool isBid;

  const OrderBookLevelWithTotal({
    required this.price,
    required this.quantity,
    required this.total,
    required this.isBid,
  });
}

class OrderBookLevel {
  final double price;
  final double quantity;

  const OrderBookLevel({required this.price, required this.quantity});
}

class OrderBookData {
  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final int lastUpdateId;

  const OrderBookData({
    required this.bids,
    required this.asks,
    this.lastUpdateId = 0,
  });

  static OrderBookData get empty => const OrderBookData(bids: [], asks: []);

  List<OrderBookLevelWithTotal> get bidsWithTotal {
    double running = 0;
    return bids.map((b) {
      running += b.quantity;
      return OrderBookLevelWithTotal(
        price: b.price,
        quantity: b.quantity,
        total: running,
        isBid: true,
      );
    }).toList();
  }

  List<OrderBookLevelWithTotal> get asksWithTotal {
    double running = 0;
    return asks.map((a) {
      running += a.quantity;
      return OrderBookLevelWithTotal(
        price: a.price,
        quantity: a.quantity,
        total: running,
        isBid: false,
      );
    }).toList();
  }

  factory OrderBookData.fromJson(Map<String, dynamic> json) {
    List<OrderBookLevel> parse(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((item) {
            if (item is List && item.length >= 2) {
              return OrderBookLevel(
                price: double.tryParse(item[0].toString()) ?? 0,
                quantity: double.tryParse(item[1].toString()) ?? 0,
              );
            }
            if (item is Map) {
              final p = (item['price'] as num?)?.toDouble() ??
                  double.tryParse(item['price']?.toString() ?? '') ??
                  0;
              final q = (item['quantity'] ?? item['qty'] ?? item['size'] as num?)
                      ?.toDouble() ??
                  double.tryParse(
                      (item['quantity'] ?? item['qty'] ?? item['size'])
                              ?.toString() ??
                          '') ??
                  0;
              return OrderBookLevel(price: p, quantity: q);
            }
            return const OrderBookLevel(price: 0, quantity: 0);
          })
          .where((l) => l.price > 0)
          .toList();
    }

    return OrderBookData(
      bids: parse(json['bids']),
      asks: parse(json['asks']),
      lastUpdateId: (json['lastUpdateId'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Ticker 24hr ───────────────────────────────────────────────────────────────

class Ticker24hrData {
  final String symbol;
  final double lastPrice;
  final double bestBid;
  final double bestAsk;
  final double priceChange;
  final double priceChangePercent;
  final double volume;
  final double high;
  final double low;

  const Ticker24hrData({
    required this.symbol,
    required this.lastPrice,
    required this.bestBid,
    required this.bestAsk,
    required this.priceChange,
    required this.priceChangePercent,
    required this.volume,
    required this.high,
    required this.low,
  });

  double get spread => bestAsk > 0 && bestBid > 0 ? bestAsk - bestBid : 0;

  String get spreadFormatted {
    if (spread <= 0 || lastPrice <= 0) return '—';
    final pct = spread / lastPrice * 100;
    return '\$${spread.toStringAsFixed(2)} (${pct.toStringAsFixed(3)}%)';
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsFixed(4)}';
  }

  String get formattedLast => _fmt(lastPrice);
  String get formattedBid => bestBid > 0 ? _fmt(bestBid) : '—';
  String get formattedAsk => bestAsk > 0 ? _fmt(bestAsk) : '—';
  String get formattedLast2 =>
      '\$${lastPrice.toStringAsFixed(lastPrice >= 100 ? 1 : 2)}';

  static double _parse(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? (v as num?)?.toDouble() ?? 0;
  }

  factory Ticker24hrData.fromJson(Map<String, dynamic> json) => Ticker24hrData(
        symbol: json['symbol']?.toString() ?? '',
        lastPrice:
            _parse(json['lastPrice'] ?? json['price'] ?? json['close']),
        bestBid: _parse(json['bidPrice'] ?? json['bestBid'] ?? json['bid']),
        bestAsk: _parse(json['askPrice'] ?? json['bestAsk'] ?? json['ask']),
        priceChange: _parse(json['priceChange']),
        priceChangePercent:
            _parse(json['priceChangePercent'] ?? json['priceChangePct']),
        volume: _parse(json['volume'] ?? json['baseVolume']),
        high: _parse(json['highPrice'] ?? json['high']),
        low: _parse(json['lowPrice'] ?? json['low']),
      );

  static Ticker24hrData get empty => const Ticker24hrData(
        symbol: '',
        lastPrice: 0,
        bestBid: 0,
        bestAsk: 0,
        priceChange: 0,
        priceChangePercent: 0,
        volume: 0,
        high: 0,
        low: 0,
      );
}

// ── Key Levels ─────────────────────────────────────────────────────────────────

class KeyLevelData {
  final double price;
  final String label;
  final String note;
  final String type;

  const KeyLevelData({
    required this.price,
    required this.label,
    required this.note,
    required this.type,
  });

  bool get isSupport =>
      type.toLowerCase().contains('support') ||
      type.toLowerCase() == 'buy';
  bool get isResistance =>
      type.toLowerCase().contains('resist') ||
      type.toLowerCase() == 'sell';
  bool get isCurrent => type.toLowerCase() == 'current';

  static String _defaultLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('major') && t.contains('resist')) return 'Major Resistance';
    if (t.contains('resist')) return 'Resistance';
    if (t.contains('major') && t.contains('support')) return 'Major Support';
    if (t.contains('support')) return 'Support';
    if (t == 'current') return 'Current Price';
    return type;
  }

  factory KeyLevelData.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase() ??
        json['levelType']?.toString().toLowerCase() ??
        'support';
    final label = json['label']?.toString() ??
        json['name']?.toString() ??
        _defaultLabel(type);
    final note = json['note']?.toString() ??
        json['description']?.toString() ??
        json['reason']?.toString() ??
        '';
    final price = (json['price'] as num?)?.toDouble() ??
        double.tryParse(json['price']?.toString() ?? '') ??
        0;
    return KeyLevelData(price: price, label: label, note: note, type: type);
  }
}