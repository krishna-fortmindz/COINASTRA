/// Dashboard data models — all fromJson are defensive, unknown fields default
/// gracefully so the UI never crashes on unexpected backend shapes.

class DashboardSummary {
  final List<MarketCoin> coins;
  final FearGreedData fearGreed;
  final List<TrendingCoin> trending;
  final List<WhaleAlert> whaleAlerts;
  final String aiSummary;
  final List<FundingRate> fundingRates;

  const DashboardSummary({
    required this.coins,
    required this.fearGreed,
    required this.trending,
    required this.whaleAlerts,
    required this.aiSummary,
    required this.fundingRates,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      coins: (json['coins'] as List? ?? [])
          .map((e) => MarketCoin.fromJson(e as Map<String, dynamic>))
          .toList(),
      fearGreed: json['fearGreed'] != null
          ? FearGreedData.fromJson(json['fearGreed'] as Map<String, dynamic>)
          : FearGreedData.empty(),
      trending: (json['trending'] as List? ?? [])
          .map((e) => TrendingCoin.fromJson(e as Map<String, dynamic>))
          .toList(),
      whaleAlerts: (json['whaleAlerts'] as List? ?? [])
          .map((e) => WhaleAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiSummary: json['aiSummary']?.toString() ?? '',
      fundingRates: (json['fundingRates'] as List? ?? [])
          .map((e) => FundingRate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MarketCoin
// ─────────────────────────────────────────────────────────────────────────────

class MarketCoin {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final List<double> sparkline;
  final String? imageUrl;

  const MarketCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.sparkline,
    this.imageUrl,
  });

  bool get positive => priceChange24h >= 0;

  String get formattedPrice {
    if (currentPrice >= 1000) {
      return '\$${currentPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},',
      )}';
    }
    if (currentPrice >= 1) return '\$${currentPrice.toStringAsFixed(2)}';
    return '\$${currentPrice.toStringAsFixed(4)}';
  }

  String get formattedChange =>
      '${positive ? '+' : ''}${priceChange24h.toStringAsFixed(2)}%';

  factory MarketCoin.fromJson(Map<String, dynamic> json) {
    final rawSparkline = json['sparkline_in_7d']?['price'] as List?;
    return MarketCoin(
      id: json['id']?.toString() ?? '',
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name']?.toString() ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      priceChange24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
      sparkline:
          rawSparkline?.map((e) => (e as num).toDouble()).toList() ?? [],
      imageUrl: json['image']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FearGreedData
// ─────────────────────────────────────────────────────────────────────────────

class FearGreedData {
  final int value;
  final String classification;
  final int? yesterday;
  final int? lastWeek;
  final int? lastMonth;

  const FearGreedData({
    required this.value,
    required this.classification,
    this.yesterday,
    this.lastWeek,
    this.lastMonth,
  });

  factory FearGreedData.empty() =>
      const FearGreedData(value: 50, classification: 'Neutral');

  factory FearGreedData.fromJson(Map<String, dynamic> json) {
    // Support Alternative.me nested format { data: [{ value, value_classification }] }
    // and flat backend format { value, classification }
    final inner = (json['data'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final src = inner ?? json;

    return FearGreedData(
      value: int.tryParse(src['value']?.toString() ?? '') ??
          (src['value'] as num?)?.toInt() ?? 50,
      classification: src['value_classification']?.toString() ??
          src['classification']?.toString() ?? 'Neutral',
      yesterday: (json['yesterday'] as num?)?.toInt(),
      lastWeek: (json['lastWeek'] as num?)?.toInt(),
      lastMonth: (json['lastMonth'] as num?)?.toInt(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FundingRate
// ─────────────────────────────────────────────────────────────────────────────

class FundingRate {
  final String symbol;
  final double rate;

  const FundingRate({required this.symbol, required this.rate});

  bool get positive => rate >= 0;

  String get formatted =>
      '${positive ? '+' : ''}${(rate * 100).toStringAsFixed(3)}%';

  bool get isHigh => rate.abs() > 0.0004; // 0.04%

  String get interpretation {
    if (rate < 0) return 'Shorts paying longs — bearish bias';
    if (rate.abs() < 0.0001) return 'Neutral — balanced positioning';
    if (rate.abs() < 0.0002) return 'Moderate long dominance';
    if (rate.abs() < 0.0004) return 'High bullish sentiment';
    return 'Very high — potential squeeze risk';
  }

  factory FundingRate.fromJson(Map<String, dynamic> json) {
    final raw = json['fundingRate'] ?? json['funding_rate'] ?? 0;
    return FundingRate(
      symbol: json['symbol']?.toString() ?? '',
      rate: double.tryParse(raw.toString()) ??
          (raw as num?)?.toDouble() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WhaleAlert
// ─────────────────────────────────────────────────────────────────────────────

class WhaleAlert {
  final String symbol;
  final double amount;
  final double amountUsd;
  final String from;
  final String to;
  final DateTime timestamp;

  const WhaleAlert({
    required this.symbol,
    required this.amount,
    required this.amountUsd,
    required this.from,
    required this.to,
    required this.timestamp,
  });

  static const _exchangeNames = {
    'binance', 'coinbase', 'kraken', 'okx', 'bybit',
    'huobi', 'kucoin', 'bitfinex', 'bitmex', 'gate',
  };

  bool get toExchange =>
      _exchangeNames.contains(to.toLowerCase());

  String get formattedAmount {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(2);
  }

  String get formattedUsd {
    if (amountUsd >= 1000000000) {
      return '\$${(amountUsd / 1000000000).toStringAsFixed(1)}B';
    }
    if (amountUsd >= 1000000) {
      return '\$${(amountUsd / 1000000).toStringAsFixed(0)}M';
    }
    return '\$${amountUsd.toStringAsFixed(0)}';
  }

  String get emoji {
    final s = symbol.toUpperCase();
    if (s == 'BTC') return '🐋';
    if (s == 'ETH') return '💎';
    if (s.contains('USD') || s.contains('USDC')) return '🏦';
    return '🐳';
  }

  factory WhaleAlert.fromJson(Map<String, dynamic> json) {
    String _name(dynamic val) {
      if (val is Map) return val['name']?.toString() ?? 'Unknown';
      return val?.toString() ?? 'Unknown';
    }

    final tsRaw = json['timestamp'] as num?;
    // Whale Alert API returns Unix seconds; millis would be > 1e12
    final ts = tsRaw != null
        ? (tsRaw > 1e12
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt())
            : DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt() * 1000))
        : DateTime.now();

    return WhaleAlert(
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      amountUsd: (json['amount_usd'] ?? json['amountUsd'] as num?)?.toDouble() ?? 0,
      from: _name(json['from']),
      to: _name(json['to']),
      timestamp: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrendingCoin
// ─────────────────────────────────────────────────────────────────────────────

class TrendingCoin {
  final String id;
  final String symbol;
  final String name;
  final double priceChange24h;

  const TrendingCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.priceChange24h,
  });

  bool get positive => priceChange24h >= 0;

  String get formattedChange =>
      '${positive ? '+' : ''}${priceChange24h.toStringAsFixed(1)}%';

  String get emoji {
    if (priceChange24h > 20) return '🚀';
    if (priceChange24h > 5) return '🔥';
    if (priceChange24h < -5) return '📉';
    return '⚡';
  }

  factory TrendingCoin.fromJson(Map<String, dynamic> json) {
    // Handle CoinGecko format: { item: { id, symbol, name, data: { price_change_percentage_24h: { usd } } } }
    // or flat format: { id, symbol, name, price_change_percentage_24h }
    final item = json['item'] as Map<String, dynamic>? ?? json;
    final data = item['data'] as Map<String, dynamic>?;
    final changeRaw = data?['price_change_percentage_24h'];
    final change = changeRaw is Map
        ? (changeRaw['usd'] as num?)?.toDouble() ?? 0
        : (changeRaw as num?)?.toDouble() ??
            (item['price_change_percentage_24h'] as num?)?.toDouble() ?? 0;

    return TrendingCoin(
      id: item['id']?.toString() ?? '',
      symbol: (item['symbol'] as String? ?? '').toUpperCase(),
      name: item['name']?.toString() ?? '',
      priceChange24h: change,
    );
  }
}
