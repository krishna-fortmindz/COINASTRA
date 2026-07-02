class AiAnalysis {
  final String type;
  final String model;
  final double? currentPriceUsd;
  final AnalysisData analysis;

  AiAnalysis({
    required this.type,
    required this.model,
    this.currentPriceUsd,
    required this.analysis,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      type: json['type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      currentPriceUsd: (json['currentPriceUsd'] as num?)?.toDouble(),
      analysis: AnalysisData.fromJson(
          json['analysis'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory AiAnalysis.fromSignalJson(Map<String, dynamic> json) {
    final price = (json['currentPrice'] as num?)?.toDouble() ?? 0;
    final pricePct = (json['priceChangePct24h'] as num?)?.toDouble() ?? 0;
    final verdict = json['verdict']?.toString() ?? 'NEUTRAL';
    final confidence = (json['confidence'] as num?)?.toInt() ?? 0;
    final symbol = json['symbol']?.toString() ?? 'BTCUSDT';
    final asset = symbol.replaceAll('USDT', '');

    final indicators = json['indicators'] as Map<String, dynamic>? ?? {};
    final rsi = (indicators['rsi'] as num?)?.toDouble() ?? 0;

    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    final fundingRegime = metrics['fundingRegime']?.toString() ?? '';
    final fundingRate = (metrics['fundingRatePct'] as num?)?.toDouble() ?? 0;
    final lsRatio = (metrics['longShortRatio'] as num?)?.toDouble() ?? 1.0;
    final sentimentScore = (metrics['sentimentScore'] as num?)?.toInt() ?? 50;

    final tradeLevels = json['tradeLevels'] as Map<String, dynamic>? ?? {};
    final entryZone = tradeLevels['entryZone'] as Map<String, dynamic>? ?? {};
    final entryMin = (entryZone['min'] as num?)?.toDouble() ?? 0;
    final tp = (tradeLevels['takeProfit'] as num?)?.toDouble() ?? 0;
    final sl = (tradeLevels['stopLoss'] as num?)?.toDouble() ?? 0;

    final reasoning =
        (json['reasoning'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final priceK = '\$${(price / 1000).toStringAsFixed(1)}K';
    final sign = pricePct >= 0 ? '+' : '';
    final rsiDesc = rsi > 70
        ? 'overbought'
        : rsi < 30
            ? 'oversold'
            : 'neutral zone';
    final lsDesc = lsRatio > 2
        ? 'crowded longs'
        : lsRatio < 0.5
            ? 'crowded shorts'
            : 'balanced';
    final summary = '$asset at $priceK ($sign${pricePct.toStringAsFixed(2)}%). '
        'Signal: $verdict — $confidence% confidence. '
        'RSI ${rsi.toStringAsFixed(1)} — $rsiDesc. '
        'Funding $fundingRegime at ${fundingRate.toStringAsFixed(4)}%. '
        'L/S ${lsRatio.toStringAsFixed(2)} — $lsDesc. '
        '${reasoning.isNotEmpty ? reasoning.first : ''}';

    final bullish = sentimentScore.clamp(0, 100);
    final bearish = ((100 - sentimentScore) * 0.6).round().clamp(0, 100);
    final neutral = (100 - bullish - bearish).clamp(0, 100);

    return AiAnalysis(
      type: 'signal',
      model: 'AI Signal',
      currentPriceUsd: price,
      analysis: AnalysisData(
        asset: asset,
        trendDirection: verdict,
        summary: summary,
        currentPriceUsd: price,
        keyLevels: KeyLevels(
          support: entryMin > 0
              ? [Level(label: 'Entry', price: entryMin, reason: 'Entry zone')]
              : [],
          resistance: tp > 0
              ? [Level(label: 'TP', price: tp, reason: 'Take profit')]
              : [],
        ),
        riskFactors: sl > 0
            ? ['\$${sl.toStringAsFixed(0)} stop loss', ...reasoning]
            : reasoning,
        confidenceScore: confidence,
        sentimentBreakdown: SentimentBreakdown(
          bullish: bullish,
          neutral: neutral,
          bearish: bearish,
        ),
        volatilityAnalysis: '',
        keyInsights: reasoning,
      ),
    );
  }
}

class AnalysisData {
  final String asset;
  final String trendDirection;
  final String summary;
  final double? currentPriceUsd;
  final KeyLevels keyLevels;
  final List<String> riskFactors;
  final int confidenceScore;
  final SentimentBreakdown sentimentBreakdown;
  final String volatilityAnalysis;
  final List<String> keyInsights;

  AnalysisData({
    required this.asset,
    required this.trendDirection,
    required this.summary,
    this.currentPriceUsd,
    required this.keyLevels,
    required this.riskFactors,
    required this.confidenceScore,
    required this.sentimentBreakdown,
    required this.volatilityAnalysis,
    required this.keyInsights,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(
      asset: json['asset']?.toString() ?? '',
      trendDirection: json['trendDirection']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      currentPriceUsd: (json['currentPriceUsd'] as num?)?.toDouble(),
      keyLevels:
          KeyLevels.fromJson(json['keyLevels'] as Map<String, dynamic>? ?? {}),
      riskFactors:
          (json['riskFactors'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      confidenceScore: (json['confidenceScore'] as num?)?.toInt() ?? 0,
      sentimentBreakdown: SentimentBreakdown.fromJson(
          json['sentimentBreakdown'] as Map<String, dynamic>? ?? {}),
      volatilityAnalysis: json['volatilityAnalysis']?.toString() ?? '',
      keyInsights:
          (json['keyInsights'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }
}

class KeyLevels {
  final List<Level> support;
  final List<Level> resistance;

  KeyLevels({required this.support, required this.resistance});

  factory KeyLevels.fromJson(Map<String, dynamic> json) {
    final sup = (json['support'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Level.fromJson)
            .toList() ??
        [];
    final res = (json['resistance'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Level.fromJson)
            .toList() ??
        [];
    return KeyLevels(support: sup, resistance: res);
  }
}

class Level {
  final String label;
  final double price;
  final String reason;

  Level({required this.label, required this.price, required this.reason});

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      label: json['label']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class SentimentBreakdown {
  final int bullish;
  final int neutral;
  final int bearish;

  SentimentBreakdown(
      {required this.bullish, required this.neutral, required this.bearish});

  factory SentimentBreakdown.fromJson(Map<String, dynamic> json) {
    return SentimentBreakdown(
      bullish: (json['bullish'] as num?)?.toInt() ?? 0,
      neutral: (json['neutral'] as num?)?.toInt() ?? 0,
      bearish: (json['bearish'] as num?)?.toInt() ?? 0,
    );
  }
}
