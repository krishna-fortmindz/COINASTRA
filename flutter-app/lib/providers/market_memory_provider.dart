import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

String? _directionFromText(String? text) {
  if (text == null) return null;
  final lower = text.toLowerCase();
  if (lower.contains('bullish')) return 'bullish';
  if (lower.contains('bearish')) return 'bearish';
  return null;
}

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

class MarketPattern {
  final String id;
  final String patternType;
  final String symbol;
  final DateTime? detectedAt;
  final String? description;
  final double? confidence; // 0–100 (similarity score)
  final String? direction;  // 'bullish' | 'bearish' | null
  final String? outcome;
  final List<String> conditions;

  const MarketPattern({
    required this.id,
    required this.patternType,
    required this.symbol,
    this.detectedAt,
    this.description,
    this.confidence,
    this.direction,
    this.outcome,
    this.conditions = const [],
  });

  factory MarketPattern.fromJson(Map<String, dynamic> j) {
    DateTime? detectedAt;
    final rawDate = j['date'] ?? j['detectedAt'] ?? j['createdAt'];
    if (rawDate != null) {
      try {
        detectedAt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    final rawConditions = j['conditions'] ?? j['keyFactors'] ?? j['factors'] ?? [];
    final conditions = (rawConditions is List)
        ? rawConditions.map((e) => e.toString()).toList()
        : <String>[];

    // Backend returns 'similarity' as 0–100 (e.g. 94.2)
    final rawConf = j['similarity'] ?? j['confidence'] ?? j['score'] ?? j['strength'];
    double? confidence;
    if (rawConf != null) {
      confidence = double.tryParse(rawConf.toString());
    }

    final outcome = (j['outcome'] ?? j['result'])?.toString();
    final direction = _directionFromText(j['direction']?.toString() ?? outcome);

    return MarketPattern(
      id: (j['id'] ?? j['_id'] ?? j['patternId'] ?? '').toString(),
      // Backend key is 'type' not 'patternType'
      patternType: (j['type'] ?? j['patternType'] ?? j['pattern'] ?? j['name'] ?? 'Unknown').toString(),
      symbol: (j['symbol'] ?? j['coin'] ?? 'BTC').toString(),
      detectedAt: detectedAt,
      description: (j['description'] ?? j['summary'] ?? j['details'])?.toString(),
      confidence: confidence,
      direction: direction,
      outcome: outcome,
      conditions: conditions,
    );
  }
}

class SimilarEvent {
  final String id;
  final String title;
  final String date;
  final int similarity; // 0–100
  final String outcome;
  final bool positive;
  final String description;
  final List<String> keyFactors;

  const SimilarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.similarity,
    required this.outcome,
    required this.positive,
    required this.description,
    this.keyFactors = const [],
  });

  factory SimilarEvent.fromJson(Map<String, dynamic> j) {
    // Backend uses 'confidence' as 0–1 (e.g. 0.6 = 60%)
    final rawConf = j['confidence'] ?? j['similarity'] ?? j['score'] ?? j['matchScore'] ?? 0;
    double rawDouble = 0;
    if (rawConf is num) {
      rawDouble = rawConf.toDouble();
    } else {
      rawDouble = double.tryParse(rawConf.toString()) ?? 0;
    }
    // If <= 1.0, it's a 0–1 fraction → multiply by 100
    final similarity = (rawDouble <= 1.0 ? (rawDouble * 100) : rawDouble).round().clamp(0, 100);

    final rawDate = (j['eventDate'] ?? j['date'] ?? j['createdAt'] ?? '').toString();
    // Backend uses 'predictedOutcome' for the outcome text
    final outcome = (j['predictedOutcome'] ?? j['outcome'] ?? j['result'] ?? '').toString();
    final positive = !outcome.toLowerCase().startsWith('correction') &&
        (outcome.toLowerCase().contains('rally') || outcome.toLowerCase().contains('+'));

    // Title from currentPattern, description from historicalMatch
    final title = (j['currentPattern'] ?? j['title'] ?? j['name'] ?? j['patternName'] ?? 'Historical Event').toString();
    final description = (j['historicalMatch'] ?? j['description'] ?? j['summary'] ?? '').toString();

    final rawFactors = j['keyFactors'] ?? j['factors'] ?? j['conditions'] ?? [];
    final keyFactors = (rawFactors is List)
        ? rawFactors.map((e) => e.toString()).toList()
        : <String>[];

    return SimilarEvent(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      title: title,
      date: rawDate,
      similarity: similarity,
      outcome: outcome,
      positive: positive,
      description: description,
      keyFactors: keyFactors,
    );
  }
}

class HistoricalCycle {
  final String period;   // cycle name, e.g. "Cycle 3 (2018 - 2022)"
  final String phase;    // peak ROI, e.g. "+2,100%"
  final String outcome;  // max drawdown, e.g. "-77.6%"
  final bool positive;

  const HistoricalCycle({
    required this.period,
    required this.phase,
    required this.outcome,
    required this.positive,
  });

  factory HistoricalCycle.fromJson(Map<String, dynamic> j) {
    // Backend: { cycle, startDate, endDate, peakRoi, maxDrawdown }
    final period = (j['cycle'] ?? j['period'] ?? j['date'] ?? j['year'] ?? '').toString();
    final phase = (j['peakRoi'] ?? j['peak_roi'] ?? j['peakReturn'] ?? j['phase'] ?? '').toString();
    final outcome = (j['maxDrawdown'] ?? j['max_drawdown'] ?? j['drawdown'] ?? j['outcome'] ?? j['result'] ?? '').toString();
    // Max drawdown is negative → show in red (positive = false)
    final positive = !outcome.startsWith('-') && outcome.startsWith('+');

    return HistoricalCycle(
      period: period,
      phase: phase,
      outcome: outcome,
      positive: positive,
    );
  }
}

class MarketCycle {
  final String currentPhase;
  final int? daysSinceStart;
  final String? description;
  final List<HistoricalCycle> historicalCycles;

  const MarketCycle({
    required this.currentPhase,
    this.daysSinceStart,
    this.description,
    this.historicalCycles = const [],
  });

  factory MarketCycle.fromJson(Map<String, dynamic> j) {
    // Backend: { symbol, currentCycle: { phase, daysSinceStart, keyLevels }, historicalCycles: [...] }
    final currentCycleMap = j['currentCycle'] as Map<String, dynamic>?;
    final currentPhase = (currentCycleMap?['phase'] ?? j['currentPhase'] ?? j['phase'] ?? 'Unknown').toString();

    int? daysSinceStart;
    final rawDays = currentCycleMap?['daysSinceStart'] ?? currentCycleMap?['daysSinceHalving'] ?? j['daysSinceStart'];
    if (rawDays != null) {
      daysSinceStart = int.tryParse(rawDays.toString());
    }

    final rawCycles = j['historicalCycles'] ?? j['cycles'] ?? j['history'] ?? [];
    final historicalCycles = (rawCycles is List)
        ? rawCycles.whereType<Map<String, dynamic>>().map(HistoricalCycle.fromJson).toList()
        : <HistoricalCycle>[];

    return MarketCycle(
      currentPhase: currentPhase,
      daysSinceStart: daysSinceStart,
      description: (j['description'] ?? j['summary'])?.toString(),
      historicalCycles: historicalCycles,
    );
  }
}

class FearGreedPoint {
  final DateTime date;
  final int value;

  const FearGreedPoint({required this.date, required this.value});

  factory FearGreedPoint.fromJson(Map<String, dynamic> j) {
    DateTime date = DateTime.now();
    final rawDate = j['date'] ?? j['timestamp'] ?? j['time'];
    if (rawDate != null) {
      try {
        date = DateTime.parse(rawDate.toString());
      } catch (_) {
        final ts = int.tryParse(rawDate.toString());
        if (ts != null) date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      }
    }
    final rawVal = j['value'] ?? j['score'] ?? j['index'] ?? 0;
    int value = rawVal is int ? rawVal : (int.tryParse(rawVal.toString()) ?? 0);
    return FearGreedPoint(date: date, value: value.clamp(0, 100));
  }
}

class MacroContext {
  final double? btcDominance;
  final int? fearGreedCurrent;
  final String? fearGreedLabel;   // regime label from API
  final List<FearGreedPoint> fearGreedHistory;
  final String? aiSummary;
  final List<String> keySignals;

  const MacroContext({
    this.btcDominance,
    this.fearGreedCurrent,
    this.fearGreedLabel,
    this.fearGreedHistory = const [],
    this.aiSummary,
    this.keySignals = const [],
  });

  factory MacroContext.fromJson(Map<String, dynamic> j) {
    // Backend: { dominance, fearGreedHistory, correlations, regimeLabel }
    double? btcDominance;
    final rawDom = j['dominance'] ?? j['btcDominance'] ?? j['btcDom'];
    if (rawDom != null) btcDominance = double.tryParse(rawDom.toString());

    final rawHistory = j['fearGreedHistory'] ?? j['history'] ?? j['fearGreedData'] ?? [];
    final fearGreedHistory = (rawHistory is List)
        ? rawHistory.whereType<Map<String, dynamic>>().map(FearGreedPoint.fromJson).toList()
        : <FearGreedPoint>[];

    // Derive current fear/greed from last history item
    final fearGreedCurrent = fearGreedHistory.isNotEmpty ? fearGreedHistory.last.value : null;

    // 'regimeLabel' is the descriptive text from backend
    final fearGreedLabel = (j['regimeLabel'] ?? j['fearGreedLabel'] ?? j['sentiment'] ?? j['label'])?.toString();

    // Build key signals from correlations map
    final List<String> keySignals = [];
    final rawSignals = j['keySignals'] ?? j['signals'] ?? j['indicators'];
    if (rawSignals is List) {
      keySignals.addAll(rawSignals.map((e) => e.toString()));
    }
    final correlations = j['correlations'];
    if (correlations is Map && keySignals.isEmpty) {
      final labels = <String, String>{
        'eth': 'ETH', 'sol': 'SOL', 'sp500': 'S&P500', 'gold': 'Gold', 'dxy': 'DXY',
      };
      correlations.forEach((k, v) {
        final num? val = v is num ? v : double.tryParse(v.toString());
        if (val != null) {
          final label = labels[k.toString()] ?? k.toString().toUpperCase();
          keySignals.add('$label: ${val.toStringAsFixed(2)} corr');
        }
      });
    }

    return MacroContext(
      btcDominance: btcDominance,
      fearGreedCurrent: fearGreedCurrent,
      fearGreedLabel: fearGreedLabel,
      fearGreedHistory: fearGreedHistory,
      aiSummary: fearGreedLabel, // show regime label as AI summary
      keySignals: keySignals,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared symbol state
// ─────────────────────────────────────────────────────────────

final memorySymbolProvider = StateProvider<String>((ref) => 'BTC');

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

final marketPatternsProvider =
    FutureProvider.autoDispose.family<List<MarketPattern>, String>((ref, symbol) async {
  final url = EndPoints.memoryPatternsWithParams(symbol: symbol, lookback: 365);
  final res = await ApiClient.instance.get<dynamic>(url);
  final body = res.data;
  List<dynamic> list = const [];
  if (body is List) {
    list = body;
  } else if (body is Map) {
    // Backend wraps as { data: { symbol, patterns: [...] } }
    final data = body['data'];
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final patterns = data['patterns'];
      if (patterns is List) list = patterns;
    } else {
      final fallback = body['patterns'] ?? body['results'];
      if (fallback is List) list = fallback;
    }
  }
  return list.whereType<Map<String, dynamic>>().map(MarketPattern.fromJson).toList();
});

final similarEventsProvider =
    FutureProvider.autoDispose.family<List<SimilarEvent>, String>((ref, symbol) async {
  final url = EndPoints.memorySimilarEventsWithParams(symbol: symbol, limit: 5);
  final res = await ApiClient.instance.get<dynamic>(url);
  final body = res.data;
  List<dynamic> list = const [];
  if (body is List) {
    list = body;
  } else if (body is Map) {
    // Backend: { data: [...] } (array directly under data)
    final inner = body['data'] ?? body['events'] ?? body['similarEvents'] ?? body['results'];
    if (inner is List) list = inner;
  }
  return list.whereType<Map<String, dynamic>>().map(SimilarEvent.fromJson).toList();
});

// Now accepts symbol so the cycle data changes per coin
final marketCyclesProvider =
    FutureProvider.autoDispose.family<MarketCycle?, String>((ref, symbol) async {
  try {
    final url = EndPoints.memoryMarketCyclesWithParams(symbol: symbol);
    final res = await ApiClient.instance.get<dynamic>(url);
    final body = res.data;
    if (body == null) return null;
    Map<String, dynamic> json;
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      json = (inner is Map<String, dynamic>) ? inner : body;
    } else {
      return null;
    }
    return MarketCycle.fromJson(json);
  } catch (_) {
    return null;
  }
});

final macroContextProvider = FutureProvider.autoDispose<MacroContext?>((ref) async {
  try {
    final res = await ApiClient.instance.get<dynamic>(EndPoints.memoryMacroContext);
    final body = res.data;
    if (body == null) return null;
    Map<String, dynamic> json;
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      json = (inner is Map<String, dynamic>) ? inner : body;
    } else {
      return null;
    }
    return MacroContext.fromJson(json);
  } catch (_) {
    return null;
  }
});
