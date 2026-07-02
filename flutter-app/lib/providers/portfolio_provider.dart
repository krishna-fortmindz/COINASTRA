import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

// ── Color lookup ───────────────────────────────────────────────────────────────

const _symbolColors = <String, Color>{
  'BTC': Color(0xFFF7931A),
  'ETH': Color(0xFF627EEA),
  'SOL': Color(0xFF9945FF),
  'BNB': Color(0xFFF3BA2F),
  'XRP': Color(0xFF346AA9),
  'ADA': Color(0xFF0033AD),
  'DOGE': Color(0xFFBA9F33),
  'ARB': Color(0xFF12AAFF),
  'OP': Color(0xFFFF0420),
  'DYDX': Color(0xFF6966FF),
  'LINK': Color(0xFF2A5ADA),
  'AVAX': Color(0xFFE84142),
};

Color colorForSymbol(String symbol, int index) {
  final key =
      symbol.toUpperCase().replaceAll('USDT', '').replaceAll('BUSD', '');
  if (_symbolColors.containsKey(key)) return _symbolColors[key]!;
  const fallbacks = [
    Color(0xFF00FF88),
    Color(0xFF4FC3F7),
    Color(0xFFCE93D8),
    Color(0xFFFFD54F),
    Color(0xFF80CBC4),
  ];
  return fallbacks[index % fallbacks.length];
}

// ── Models ─────────────────────────────────────────────────────────────────────

class LivePnl {
  final double? currentPrice;
  final double unrealizedPnlUsd;
  final double unrealizedPnlPct;
  final double roePct;
  final double positionValueUsd;
  final double? liqDistancePct;
  final double? currentPriceInr;
  final double? unrealizedPnlInr;
  final double? positionValueInr;
  final double? marginInr;

  const LivePnl({
    required this.currentPrice,
    required this.unrealizedPnlUsd,
    required this.unrealizedPnlPct,
    required this.roePct,
    required this.positionValueUsd,
    required this.liqDistancePct,
    this.currentPriceInr,
    this.unrealizedPnlInr,
    this.positionValueInr,
    this.marginInr,
  });

  factory LivePnl.fromJson(Map<String, dynamic> j) => LivePnl(
        currentPrice: (j['currentPrice'] as num?)?.toDouble(),
        unrealizedPnlUsd: (j['unrealizedPnlUsd'] as num?)?.toDouble() ?? 0,
        unrealizedPnlPct: (j['unrealizedPnlPct'] as num?)?.toDouble() ?? 0,
        roePct: (j['roePct'] as num?)?.toDouble() ?? 0,
        positionValueUsd: (j['positionValueUsd'] as num?)?.toDouble() ?? 0,
        liqDistancePct: (j['liqDistancePct'] as num?)?.toDouble(),
        currentPriceInr: (j['currentPriceInr'] as num?)?.toDouble(),
        unrealizedPnlInr: (j['unrealizedPnlInr'] as num?)?.toDouble(),
        positionValueInr: (j['positionValueInr'] as num?)?.toDouble(),
        marginInr: (j['marginInr'] as num?)?.toDouble(),
      );
}

class RealizedPnl {
  final double realizedPnlUsd;
  final double realizedPnlPct;
  final double roePct;
  final double? realizedPnlInr;

  const RealizedPnl({
    required this.realizedPnlUsd,
    required this.realizedPnlPct,
    required this.roePct,
    this.realizedPnlInr,
  });

  factory RealizedPnl.fromJson(Map<String, dynamic> j) => RealizedPnl(
        realizedPnlUsd: (j['realizedPnlUsd'] as num?)?.toDouble() ?? 0,
        realizedPnlPct: (j['realizedPnlPct'] as num?)?.toDouble() ?? 0,
        roePct: (j['roePct'] as num?)?.toDouble() ?? 0,
        realizedPnlInr: (j['realizedPnlInr'] as num?)?.toDouble(),
      );
}

class PortfolioPosition {
  final String id;
  final String symbol;
  final String coinId;
  final String direction;
  final double entryPrice;
  final double quantity;
  final int leverage;
  final double margin;
  final double? liquidationPrice;
  final String notes;
  final String status;
  final double? exitPrice;
  final DateTime? closedAt;
  final DateTime createdAt;
  final LivePnl? live;
  final RealizedPnl? realized;

  const PortfolioPosition({
    required this.id,
    required this.symbol,
    required this.coinId,
    required this.direction,
    required this.entryPrice,
    required this.quantity,
    required this.leverage,
    required this.margin,
    this.liquidationPrice,
    required this.notes,
    required this.status,
    this.exitPrice,
    this.closedAt,
    required this.createdAt,
    this.live,
    this.realized,
  });

  bool get isOpen => status == 'open';
  bool get isLong => direction == 'long';
  double get pnlUsd =>
      live?.unrealizedPnlUsd ?? realized?.realizedPnlUsd ?? 0;
  double get pnlPct =>
      live?.unrealizedPnlPct ?? realized?.realizedPnlPct ?? 0;
  double get roe => live?.roePct ?? realized?.roePct ?? 0;
  bool get positive => pnlUsd >= 0;

  factory PortfolioPosition.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return PortfolioPosition(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      symbol: j['symbol']?.toString() ?? '',
      coinId: j['coinId']?.toString() ?? '',
      direction: j['direction']?.toString() ?? 'long',
      entryPrice: (j['entryPrice'] as num?)?.toDouble() ?? 0,
      quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
      leverage: (j['leverage'] as num?)?.toInt() ?? 1,
      margin: (j['margin'] as num?)?.toDouble() ?? 0,
      liquidationPrice: (j['liquidationPrice'] as num?)?.toDouble(),
      notes: j['notes']?.toString() ?? '',
      status: j['status']?.toString() ?? 'open',
      exitPrice: (j['exitPrice'] as num?)?.toDouble(),
      closedAt: parseDate(j['closedAt']),
      createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
      live: j['live'] is Map
          ? LivePnl.fromJson(Map<String, dynamic>.from(j['live'] as Map))
          : null,
      realized: j['realized'] is Map
          ? RealizedPnl.fromJson(
              Map<String, dynamic>.from(j['realized'] as Map))
          : null,
    );
  }
}

class PortfolioTotals {
  final double totalMarginUsd;
  final double totalPnlUsd;
  final double totalValueUsd;
  final double totalPnlPct;
  final int positionCount;
  final String currency;
  final double? totalMarginInr;
  final double? totalPnlInr;
  final double? totalValueInr;
  final double? inrRate;

  const PortfolioTotals({
    required this.totalMarginUsd,
    required this.totalPnlUsd,
    required this.totalValueUsd,
    required this.totalPnlPct,
    required this.positionCount,
    required this.currency,
    this.totalMarginInr,
    this.totalPnlInr,
    this.totalValueInr,
    this.inrRate,
  });

  bool get positive => totalPnlUsd >= 0;

  factory PortfolioTotals.empty() => const PortfolioTotals(
        totalMarginUsd: 0,
        totalPnlUsd: 0,
        totalValueUsd: 0,
        totalPnlPct: 0,
        positionCount: 0,
        currency: 'USD',
      );

  factory PortfolioTotals.fromJson(Map<String, dynamic> j) => PortfolioTotals(
        totalMarginUsd: (j['totalMarginUsd'] as num?)?.toDouble() ?? 0,
        totalPnlUsd: (j['totalPnlUsd'] as num?)?.toDouble() ?? 0,
        totalValueUsd: (j['totalValueUsd'] as num?)?.toDouble() ?? 0,
        totalPnlPct: (j['totalPnlPct'] as num?)?.toDouble() ?? 0,
        positionCount: (j['positionCount'] as num?)?.toInt() ?? 0,
        currency: j['currency']?.toString() ?? 'USD',
        totalMarginInr: (j['totalMarginInr'] as num?)?.toDouble(),
        totalPnlInr: (j['totalPnlInr'] as num?)?.toDouble(),
        totalValueInr: (j['totalValueInr'] as num?)?.toDouble(),
        inrRate: (j['inrRate'] as num?)?.toDouble(),
      );
}

class PositionTip {
  final String symbol;
  final String tip;
  final String risk;

  const PositionTip(
      {required this.symbol, required this.tip, required this.risk});

  Color get riskColor {
    switch (risk) {
      case 'high':
        return const Color(0xFFFF4444);
      case 'medium':
        return const Color(0xFFFFAA00);
      default:
        return const Color(0xFF00FF88);
    }
  }

  factory PositionTip.fromJson(Map<String, dynamic> j) => PositionTip(
        symbol: j['symbol']?.toString() ?? '',
        tip: j['tip']?.toString() ?? '',
        risk: j['risk']?.toString() ?? 'medium',
      );
}

class PortfolioTipsData {
  final List<PositionTip> positionTips;
  final String overallAdvice;
  final int riskScore;
  final String model;

  const PortfolioTipsData({
    required this.positionTips,
    required this.overallAdvice,
    required this.riskScore,
    required this.model,
  });

  factory PortfolioTipsData.fromJson(Map<String, dynamic> j) =>
      PortfolioTipsData(
        positionTips: (j['positionTips'] as List?)
                ?.whereType<Map>()
                .map((e) =>
                    PositionTip.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        overallAdvice: j['overallAdvice']?.toString() ?? '',
        riskScore: (j['riskScore'] as num?)?.toInt() ?? 0,
        model: j['model']?.toString() ?? '',
      );
}

// ── State ──────────────────────────────────────────────────────────────────────

class PortfolioState {
  final List<PortfolioPosition> openPositions;
  final List<PortfolioPosition> closedPositions;
  final PortfolioTotals totals;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final PortfolioTipsData? tips;
  final bool tipsLoading;
  final String currency;

  const PortfolioState({
    this.openPositions = const [],
    this.closedPositions = const [],
    this.totals = const PortfolioTotals(
      totalMarginUsd: 0,
      totalPnlUsd: 0,
      totalValueUsd: 0,
      totalPnlPct: 0,
      positionCount: 0,
      currency: 'USD',
    ),
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.tips,
    this.tipsLoading = false,
    this.currency = 'USD',
  });

  PortfolioState copyWith({
    List<PortfolioPosition>? openPositions,
    List<PortfolioPosition>? closedPositions,
    PortfolioTotals? totals,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    PortfolioTipsData? tips,
    bool? tipsLoading,
    String? currency,
    bool clearError = false,
    bool clearTips = false,
  }) =>
      PortfolioState(
        openPositions: openPositions ?? this.openPositions,
        closedPositions: closedPositions ?? this.closedPositions,
        totals: totals ?? this.totals,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        tips: clearTips ? null : (tips ?? this.tips),
        tipsLoading: tipsLoading ?? this.tipsLoading,
        currency: currency ?? this.currency,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  PortfolioNotifier() : super(const PortfolioState()) {
    fetch();
  }

  Future<void> fetch({String? currency}) async {
    final cur = currency ?? state.currency;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ApiClient.instance;
      final results = await Future.wait([
        api.get(EndPoints.portfolioWithParams(status: 'open', currency: cur)),
        api.get(EndPoints.portfolioWithParams(status: 'closed', currency: cur)),
      ]);

      List<PortfolioPosition> open = [];
      List<PortfolioPosition> closed = [];
      PortfolioTotals totals = PortfolioTotals.empty();

      final openRaw = results[0].data;
      if (openRaw is Map && openRaw['success'] == true) {
        final data =
            Map<String, dynamic>.from(openRaw['data'] as Map? ?? {});
        open = (data['positions'] as List? ?? [])
            .whereType<Map>()
            .map((e) =>
                PortfolioPosition.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (data['totals'] is Map) {
          totals = PortfolioTotals.fromJson(
              Map<String, dynamic>.from(data['totals'] as Map));
        }
      }

      final closedRaw = results[1].data;
      if (closedRaw is Map && closedRaw['success'] == true) {
        final data =
            Map<String, dynamic>.from(closedRaw['data'] as Map? ?? {});
        closed = (data['positions'] as List? ?? [])
            .whereType<Map>()
            .map((e) =>
                PortfolioPosition.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      state = state.copyWith(
        openPositions: open,
        closedPositions: closed,
        totals: totals,
        isLoading: false,
        currency: cur,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load portfolio. Please try again.',
      );
    }
  }

  Future<bool> addPosition(Map<String, dynamic> body) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res =
          await ApiClient.instance.post(EndPoints.portfolioPositions, data: body);
      if (res.data is Map && res.data['success'] == true) {
        state = state.copyWith(isSubmitting: false);
        await fetch();
        return true;
      }
      throw Exception(
          (res.data as Map?)?['message']?.toString() ?? 'Failed to add position');
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> closePosition(String id, double exitPrice) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await ApiClient.instance.post(
        EndPoints.closePortfolioPosition(id),
        data: {'exitPrice': exitPrice},
      );
      if (res.data is Map && res.data['success'] == true) {
        state = state.copyWith(isSubmitting: false);
        await fetch();
        return true;
      }
      throw Exception(
          (res.data as Map?)?['message']?.toString() ?? 'Failed to close position');
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deletePosition(String id) async {
    final prev = List<PortfolioPosition>.from(state.openPositions);
    // Optimistic removal
    state = state.copyWith(
      openPositions: prev.where((p) => p.id != id).toList(),
    );
    try {
      final res =
          await ApiClient.instance.delete(EndPoints.portfolioPosition(id));
      if (res.data is Map && res.data['success'] == true) {
        fetch();
        return true;
      }
      throw Exception(
          (res.data as Map?)?['message']?.toString() ?? 'Failed to delete');
    } catch (e) {
      state = state.copyWith(
        openPositions: prev,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> fetchTips() async {
    if (state.openPositions.isEmpty) return;
    state = state.copyWith(tipsLoading: true);
    try {
      final res = await ApiClient.instance.get(EndPoints.portfolioTips);
      if (res.data is Map && res.data['success'] == true) {
        state = state.copyWith(
          tips: PortfolioTipsData.fromJson(
              Map<String, dynamic>.from(res.data['data'] as Map)),
          tipsLoading: false,
        );
      } else {
        state = state.copyWith(tipsLoading: false);
      }
    } catch (_) {
      state = state.copyWith(tipsLoading: false);
    }
  }

  void toggleCurrency() {
    final next = state.currency == 'USD' ? 'INR' : 'USD';
    fetch(currency: next);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>(
  (_) => PortfolioNotifier(),
);
