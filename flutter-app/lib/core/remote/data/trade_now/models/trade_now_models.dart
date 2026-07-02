enum VerdictType { bullish, bearish, caution, neutral }

// ── Aggregated container ─────────────────────────────────────────────────────

class TradeNowData {
  final SignalData signal;
  final SentimentData sentiment;
  final OpenInterestData openInterest;
  final LongShortData longShort;
  final LiquidationData liquidations;
  final FundingRateInfo funding;
  final List<HistoricalSetup> history;

  const TradeNowData({
    required this.signal,
    required this.sentiment,
    required this.openInterest,
    required this.longShort,
    required this.liquidations,
    required this.funding,
    required this.history,
  });
}

// ── Signal ───────────────────────────────────────────────────────────────────

class SignalData {
  final double price;
  final String verdictLabel;
  final VerdictType verdictType;
  final int confidence;
  final String entry;
  final String takeProfit;
  final String stopLoss;
  final String riskReward;
  final String reasoning;
  final bool futuresAvailable;
  final bool coinNotSupported;
  // Raw metrics from the signal response — used as fallback for cards whose
  // separate endpoints fail (long/short, liquidation wall, etc.)
  final Map<String, dynamic> rawMetrics;

  const SignalData({
    required this.price,
    required this.verdictLabel,
    required this.verdictType,
    required this.confidence,
    required this.entry,
    required this.takeProfit,
    required this.stopLoss,
    required this.riskReward,
    required this.reasoning,
    this.futuresAvailable = true,
    this.coinNotSupported = false,
    this.rawMetrics = const {},
  });

  String get verdictIcon {
    switch (verdictType) {
      case VerdictType.bullish: return '✅';
      case VerdictType.bearish: return '🔴';
      case VerdictType.caution: return '⚠️';
      case VerdictType.neutral: return '⏸️';
    }
  }

  // Maps "BUY"→"LONG" and "SELL"→"SHORT" so futures users aren't confused.
  String get displayVerdictLabel {
    final upper = verdictLabel.toUpperCase();
    if (upper.contains('BUY')) {
      return verdictLabel.replaceAll(RegExp(r'BUY', caseSensitive: false), 'LONG');
    }
    if (upper.contains('SELL')) {
      return verdictLabel.replaceAll(RegExp(r'SELL', caseSensitive: false), 'SHORT');
    }
    return verdictLabel;
  }

  String get formattedPrice {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},',
      )}';
    }
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }

  static VerdictType _parseType(String label) {
    final v = label.toUpperCase();
    if (v.contains('BULLISH')) return VerdictType.bullish;
    if (v.contains('BEARISH') || v.contains('EXTREME')) return VerdictType.bearish;
    if (v.contains('CAUTION')) return VerdictType.caution;
    return VerdictType.neutral;
  }

  factory SignalData.fromJson(Map<String, dynamic> json) {
    final label = json['verdict']?.toString() ??
        json['verdictLabel']?.toString() ?? 'NEUTRAL';
    final levels = json['tradeLevels'] as Map<String, dynamic>? ?? {};
    final entryZone = levels['entryZone'] as Map<String, dynamic>? ?? {};
    final entryMin = (entryZone['min'] as num?)?.toDouble();
    final entryMax = (entryZone['max'] as num?)?.toDouble();
    final String entryStr;
    if (entryMin != null && entryMax != null) {
      entryStr = '${_formatPrice(entryMin)}–${_formatPrice(entryMax)}';
    } else {
      entryStr = json['entry']?.toString() ?? '—';
    }
    final reasoningRaw = json['reasoning'];
    final String reasoningStr;
    if (reasoningRaw is List) {
      reasoningStr = reasoningRaw.join(' ');
    } else {
      reasoningStr = reasoningRaw?.toString() ?? json['analysis']?.toString() ?? '';
    }
    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    return SignalData(
      price: (json['currentPrice'] ?? json['price'] as num?)?.toDouble() ?? 0,
      verdictLabel: label,
      verdictType: _parseType(label),
      confidence: (json['confidence'] as num?)?.toInt() ?? 50,
      entry: entryStr,
      takeProfit: _formatPrice(levels['takeProfit'] ?? json['takeProfit']),
      stopLoss: _formatPrice(levels['stopLoss'] ?? json['stopLoss']),
      riskReward: levels['riskReward']?.toString() ?? json['riskReward']?.toString() ?? '—',
      reasoning: reasoningStr,
      futuresAvailable: json['futuresAvailable'] as bool? ??
          json['futures_available'] as bool? ?? true,
      coinNotSupported: json['coin_not_supported'] as bool? ??
          json['coinNotSupported'] as bool? ?? false,
      rawMetrics: metrics,
    );
  }

  static String _formatPrice(dynamic v) {
    if (v == null) return '—';
    final d = (v as num?)?.toDouble() ?? double.tryParse(v.toString());
    if (d == null) return v.toString();
    if (d >= 1000) {
      return '\$${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    if (d >= 1) return '\$${d.toStringAsFixed(2)}';
    if (d >= 0.001) return '\$${d.toStringAsFixed(4)}';
    return '\$${d.toStringAsFixed(6)}';
  }

  static SignalData get empty => const SignalData(
    price: 0, verdictLabel: 'Loading…', verdictType: VerdictType.neutral,
    confidence: 0, entry: '—', takeProfit: '—', stopLoss: '—',
    riskReward: '—', reasoning: '',
  );
}

// ── Sentiment ─────────────────────────────────────────────────────────────────

class SentimentData {
  final int score;
  final String label;

  const SentimentData({required this.score, required this.label});

  factory SentimentData.fromJson(Map<String, dynamic> json) => SentimentData(
    score: (json['score'] as num?)?.toInt() ??
        (json['sentiment'] as num?)?.toInt() ?? 50,
    label: json['label']?.toString() ?? json['sentiment_label']?.toString() ?? 'Neutral',
  );

  static const empty = SentimentData(score: 50, label: 'Neutral');
}

// ── Open Interest ─────────────────────────────────────────────────────────────

class OpenInterestData {
  final double value;
  final double changePercent;
  final String changeLabel;
  final String timeframe;

  const OpenInterestData({
    required this.value,
    required this.changePercent,
    required this.changeLabel,
    required this.timeframe,
  });

  String get formattedChange =>
      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(0)}% ($timeframe)';

  factory OpenInterestData.fromJson(Map<String, dynamic> json) => OpenInterestData(
    value: (json['openInterest'] ?? json['value'] as num?)?.toDouble() ?? 0,
    changePercent: (json['changePct'] ?? json['changePercent'] ?? json['change'] as num?)?.toDouble() ?? 0,
    changeLabel: json['trend']?.toString() ?? json['changeLabel']?.toString() ?? json['label']?.toString() ?? 'Stable',
    timeframe: json['period']?.toString() ?? json['timeframe']?.toString() ?? '6h',
  );

  static const empty = OpenInterestData(
    value: 0, changePercent: 0, changeLabel: 'Stable', timeframe: '6h',
  );
}

// ── Long / Short ──────────────────────────────────────────────────────────────

class LongShortData {
  final double ratio;
  final String label;

  const LongShortData({required this.ratio, required this.label});

  String get formattedRatio => ratio.toStringAsFixed(2);

  static String labelFromRatio(double ratio) {
    if (ratio >= 2.5) return 'Crowded Longs';
    if (ratio >= 1.5) return 'Long-Heavy';
    if (ratio <= 0.4) return 'Crowded Shorts';
    if (ratio <= 0.67) return 'Short-Heavy';
    return 'Balanced';
  }

  factory LongShortData.fromJson(Map<String, dynamic> json) {
    final ratio = (json['ratio'] ?? json['longShortRatio'] as num?)?.toDouble() ?? 1.0;
    return LongShortData(
      ratio: ratio,
      label: json['label']?.toString() ?? json['sentiment']?.toString() ?? labelFromRatio(ratio),
    );
  }

  factory LongShortData.fromMetrics(Map<String, dynamic> metrics) {
    final ratio = (metrics['longShortRatio'] as num?)?.toDouble() ?? 1.0;
    return LongShortData(ratio: ratio, label: labelFromRatio(ratio));
  }

  static const empty = LongShortData(ratio: 1.0, label: 'Balanced');
}

// ── Liquidations ──────────────────────────────────────────────────────────────

class LiquidationData {
  final double wallPrice;
  final String side;
  final bool unavailable;

  const LiquidationData({
    required this.wallPrice,
    required this.side,
    this.unavailable = false,
  });

  String get formattedWall {
    if (wallPrice >= 1000) {
      return '\$${wallPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},',
      )}';
    }
    if (wallPrice >= 1) return '\$${wallPrice.toStringAsFixed(2)}';
    return '\$${wallPrice.toStringAsFixed(4)}';
  }

  String get capitalizedSide =>
      side.isEmpty ? 'Below' : '${side[0].toUpperCase()}${side.substring(1).toLowerCase()}';

  factory LiquidationData.fromJson(Map<String, dynamic> json) {
    if (json['unavailable'] == true) {
      return const LiquidationData(wallPrice: 0, side: 'Below', unavailable: true);
    }
    // API returns liquidationWallBelow / liquidationWallAbove as nested objects
    final below = json['liquidationWallBelow'] as Map<String, dynamic>?;
    final above = json['liquidationWallAbove'] as Map<String, dynamic>?;
    // Prefer the below wall; fall back to flat fields if shape differs
    double wallPrice = 0;
    String side = 'Below';
    if (below != null) {
      wallPrice = (below['price'] as num?)?.toDouble() ?? 0;
      side = 'Below';
    } else if (above != null) {
      wallPrice = (above['price'] as num?)?.toDouble() ?? 0;
      side = 'Above';
    } else {
      wallPrice = (json['wallPrice'] ?? json['price'] as num?)?.toDouble() ?? 0;
      side = json['side']?.toString() ?? 'Below';
    }
    return LiquidationData(wallPrice: wallPrice, side: side);
  }

  // Signal metrics has liquidationWallBelow as a flat number, not an object.
  factory LiquidationData.fromMetrics(Map<String, dynamic> metrics) {
    final below = (metrics['liquidationWallBelow'] as num?)?.toDouble();
    final above = (metrics['liquidationWallAbove'] as num?)?.toDouble();
    if (below != null && below > 0) {
      return LiquidationData(wallPrice: below, side: 'Below');
    }
    if (above != null && above > 0) {
      return LiquidationData(wallPrice: above, side: 'Above');
    }
    return const LiquidationData(wallPrice: 0, side: 'Below', unavailable: true);
  }

  static const empty = LiquidationData(wallPrice: 0, side: 'Below');
}

// ── Funding Rate (trade-now specific) ────────────────────────────────────────

class FundingRateInfo {
  final double rate;

  const FundingRateInfo({required this.rate});

  String get formatted =>
      '${rate >= 0 ? '+' : ''}${(rate * 100).toStringAsFixed(3)}%';

  String get level {
    final abs = rate.abs();
    if (abs > 0.0008) return 'Very High';
    if (abs > 0.0005) return 'High';
    if (abs > 0.0003) return 'Elevated';
    if (rate < -0.0001) return 'Slightly Negative';
    if (abs < 0.0001) return 'Low';
    return 'Neutral';
  }

  factory FundingRateInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['fundingRate'] ?? json['rate'] ?? json['funding_rate'] ?? 0;
    return FundingRateInfo(
      rate: double.tryParse(raw.toString()) ?? (raw as num?)?.toDouble() ?? 0,
    );
  }

  static const empty = FundingRateInfo(rate: 0);
}

// ── Historical Setup ──────────────────────────────────────────────────────────

class HistoricalSetup {
  final String title;
  final String description;
  final String outcome;
  final bool positive;

  const HistoricalSetup({
    required this.title,
    required this.description,
    required this.outcome,
    required this.positive,
  });

  factory HistoricalSetup.fromJson(Map<String, dynamic> json) {
    // API shape: { asset, period, setup, outcomePct }
    final asset = json['asset']?.toString() ?? '';
    final period = json['period']?.toString() ?? '';
    final outcomePct = (json['outcomePct'] as num?)?.toDouble();
    final String outcome;
    final bool positive;
    if (outcomePct != null) {
      outcome = '${outcomePct >= 0 ? '+' : ''}${outcomePct.toStringAsFixed(0)}%';
      positive = outcomePct >= 0;
    } else {
      outcome = json['outcome']?.toString() ?? json['result']?.toString() ?? '—';
      positive = json['positive'] as bool? ?? outcome.startsWith('+');
    }
    return HistoricalSetup(
      title: (asset.isNotEmpty && period.isNotEmpty)
          ? '$asset · $period'
          : json['title']?.toString() ?? '',
      description: json['setup']?.toString() ?? json['description']?.toString() ?? json['summary']?.toString() ?? '',
      outcome: outcome,
      positive: positive,
    );
  }
}