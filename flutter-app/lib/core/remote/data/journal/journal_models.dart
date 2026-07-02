double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
double? _toDoubleOpt(dynamic v) =>
    v == null ? null : (v as num?)?.toDouble();

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

// ── Journal Entry ─────────────────────────────────────────────────────────────

class JournalEntry {
  final String id;
  final String pair;
  final String direction; // long | short
  final double entryPrice;
  final double? exitPrice;
  final double size;
  final double? pnlUsd;
  final double? pnlPercent;
  final DateTime? entryAt;
  final DateTime? exitAt;
  final String? notes;
  final String? psychology;
  final String? strategy;
  final String? outcome; // win | loss | breakeven
  final DateTime? createdAt;

  const JournalEntry({
    required this.id,
    required this.pair,
    required this.direction,
    required this.entryPrice,
    this.exitPrice,
    required this.size,
    this.pnlUsd,
    this.pnlPercent,
    this.entryAt,
    this.exitAt,
    this.notes,
    this.psychology,
    this.strategy,
    this.outcome,
    this.createdAt,
  });

  bool get isOpen => exitPrice == null || outcome == null;
  bool get isWin => outcome == 'win';

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id']?.toString() ?? '',
        pair: j['pair']?.toString() ?? '',
        direction: j['direction']?.toString() ?? 'long',
        entryPrice: _toDouble(j['entryPrice'] ?? j['entry_price']),
        exitPrice: _toDoubleOpt(j['exitPrice'] ?? j['exit_price']),
        size: _toDouble(j['positionSize'] ?? j['size']),
        pnlUsd: _toDoubleOpt(j['pnlUsd'] ?? j['pnl_usd']),
        pnlPercent: _toDoubleOpt(j['pnlPercent'] ?? j['pnl_percent']),
        entryAt: _parseDate(j['entryAt'] ?? j['entry_at']),
        exitAt: _parseDate(j['exitAt'] ?? j['exit_at']),
        notes: j['notes']?.toString(),
        psychology: j['psychology']?.toString(),
        strategy: j['strategy']?.toString(),
        outcome: j['outcome']?.toString(),
        createdAt: _parseDate(j['createdAt'] ?? j['created_at']),
      );
}

// ── Psychology Pattern ────────────────────────────────────────────────────────

class PsychologyPattern {
  final String psychology;
  final double winRate;
  final int trades;

  const PsychologyPattern({
    required this.psychology,
    required this.winRate,
    required this.trades,
  });

  factory PsychologyPattern.fromJson(Map<String, dynamic> j) =>
      PsychologyPattern(
        psychology: j['psychology']?.toString() ?? '',
        winRate: _toDouble(j['winRate'] ?? j['win_rate']),
        trades: (j['trades'] as num?)?.toInt() ?? 0,
      );
}

// ── Journal Stats ─────────────────────────────────────────────────────────────

class JournalStats {
  final double winRate;
  final double avgRr;
  final double profitFactor;
  final double totalPnl;
  final int totalTrades;
  final List<PsychologyPattern> psychologyPatterns;
  final List<String> aiInsights;

  const JournalStats({
    required this.winRate,
    required this.avgRr,
    required this.profitFactor,
    required this.totalPnl,
    required this.totalTrades,
    required this.psychologyPatterns,
    required this.aiInsights,
  });

  factory JournalStats.fromJson(Map<String, dynamic> j) {
    final rawPatterns =
        j['psychologyPatterns'] ?? j['psychology_patterns'] ?? [];
    final patterns = (rawPatterns as List)
        .whereType<Map>()
        .map((m) => PsychologyPattern.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    final rawInsights =
        j['aiInsights'] ?? j['ai_insights'] ?? j['insights'] ?? [];
    final insights =
        (rawInsights as List).whereType<String>().toList();

    return JournalStats(
      winRate: _toDouble(j['winRate'] ?? j['win_rate']),
      avgRr: _toDouble(j['avgRr'] ?? j['avg_rr'] ?? j['averageRr']),
      profitFactor: _toDouble(j['profitFactor'] ?? j['profit_factor']),
      totalPnl: _toDouble(j['totalPnl'] ?? j['total_pnl']),
      totalTrades:
          (j['totalTrades'] ?? j['total_trades'] as num?)?.toInt() ?? 0,
      psychologyPatterns: patterns,
      aiInsights: insights,
    );
  }
}
