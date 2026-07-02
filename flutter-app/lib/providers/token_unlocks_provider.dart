import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class TokenUnlock {
  final String id;
  final String symbol;
  final String name;
  final String? emoji;
  final String? imageUrl;
  final DateTime? unlockDate;
  final int? daysLeft;
  final String amount;
  final double? amountRaw;
  final double? valueUsd;
  final double? supplyPct;
  final String riskLevel;
  final String? priceImpact;
  final String? category;
  final String? notes;

  const TokenUnlock({
    required this.id,
    required this.symbol,
    required this.name,
    this.emoji,
    this.imageUrl,
    this.unlockDate,
    this.daysLeft,
    required this.amount,
    this.amountRaw,
    this.valueUsd,
    this.supplyPct,
    required this.riskLevel,
    this.priceImpact,
    this.category,
    this.notes,
  });

  factory TokenUnlock.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ??
        j['_id']?.toString() ??
        j['symbol']?.toString() ??
        '';

    final symbol = (j['symbol']?.toString() ?? '').toUpperCase();
    // Backend uses 'projectName', not 'name'
    final name = j['projectName']?.toString() ??
        j['name']?.toString() ??
        j['project']?.toString() ??
        symbol;
    final emoji = j['emoji']?.toString();
    final imageUrl = j['imageUrl']?.toString() ?? j['image']?.toString();

    final rawDate = j['unlockDate'] ?? j['unlock_date'] ?? j['date'] ?? j['scheduledDate'];
    DateTime? unlockDate;
    if (rawDate != null) {
      unlockDate = DateTime.tryParse(rawDate.toString());
    }
    int? daysLeft;
    if (unlockDate != null) {
      daysLeft = unlockDate.difference(DateTime.now()).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    final rawAmount = j['amountTokens'] ?? j['amount'] ?? j['tokenAmount'];
    double? amountRaw;
    if (rawAmount is num) {
      amountRaw = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amountRaw = double.tryParse(rawAmount);
    }
    final amount = amountRaw != null
        ? '${_formatCompact(amountRaw)} $symbol'
        : (rawAmount?.toString() ?? '—');

    final rawValue = j['valueUsd'] ?? j['value_usd'] ?? j['usdValue'] ?? j['marketValue'];
    double? valueUsd;
    if (rawValue is num) {
      valueUsd = rawValue.toDouble();
    } else if (rawValue is String) {
      valueUsd = double.tryParse(rawValue);
    }

    final rawPct = j['supplyPercent'] ?? j['supply_pct'] ?? j['percentOfSupply'] ?? j['supplyPct'];
    double? supplyPct;
    if (rawPct is num) {
      supplyPct = rawPct.toDouble();
    } else if (rawPct is String) {
      supplyPct = double.tryParse(rawPct);
    }

    final rawRisk = j['riskLevel'] ?? j['risk_level'] ?? j['risk'];
    String riskLevel;
    if (rawRisk != null) {
      riskLevel = rawRisk.toString().toUpperCase();
    } else if (supplyPct != null) {
      if (supplyPct > 5) {
        riskLevel = 'EXTREME';
      } else if (supplyPct > 2) {
        riskLevel = 'HIGH';
      } else if (supplyPct > 1) {
        riskLevel = 'MEDIUM';
      } else {
        riskLevel = 'LOW';
      }
    } else {
      riskLevel = 'LOW';
    }

    final priceImpact = j['priceImpact']?.toString() ??
        j['price_impact']?.toString() ??
        j['estimatedImpact']?.toString();

    final category = j['category']?.toString() ??
        j['vestingType']?.toString() ??
        j['type']?.toString();

    final notes = j['notes']?.toString() ??
        j['description']?.toString() ??
        j['aiInsight']?.toString() ??
        j['insight']?.toString();

    return TokenUnlock(
      id: id,
      symbol: symbol,
      name: name,
      emoji: emoji,
      imageUrl: imageUrl,
      unlockDate: unlockDate,
      daysLeft: daysLeft,
      amount: amount,
      amountRaw: amountRaw,
      valueUsd: valueUsd,
      supplyPct: supplyPct,
      riskLevel: riskLevel,
      priceImpact: priceImpact,
      category: category,
      notes: notes,
    );
  }
}

String _formatCompact(double v) {
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

List<TokenUnlock> _parseList(Map<String, dynamic> raw) {
  final list = (raw['data'] as List?) ?? (raw['unlocks'] as List?) ?? const [];
  return list.whereType<Map<String, dynamic>>().map(TokenUnlock.fromJson).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final upcomingUnlocksProvider = FutureProvider.autoDispose<List<TokenUnlock>>((ref) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    EndPoints.tokenUnlocksUpcomingWithParams(days: 30),
  );
  return _parseList(res.data ?? {});
});

final allUnlocksProvider = FutureProvider.autoDispose.family<List<TokenUnlock>, int>((ref, page) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    EndPoints.tokenUnlocksWithParams(page: page, limit: 20),
  );
  return _parseList(res.data ?? {});
});
