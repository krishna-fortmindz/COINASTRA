import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

// ── Response models ───────────────────────────────────────────────────────────

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

class PositionSizeResult {
  final double positionSize;
  final double maxLoss;
  final double liquidationPrice;
  final String riskLevel;

  const PositionSizeResult({
    required this.positionSize,
    required this.maxLoss,
    required this.liquidationPrice,
    required this.riskLevel,
  });

  factory PositionSizeResult.fromJson(Map<String, dynamic> j) =>
      PositionSizeResult(
        positionSize: _toDouble(j['positionSize'] ?? j['position_size']),
        maxLoss: _toDouble(j['maxLoss'] ?? j['max_loss']),
        liquidationPrice:
            _toDouble(j['liquidationPrice'] ?? j['liquidation_price']),
        riskLevel: j['riskLevel']?.toString() ??
            j['risk_level']?.toString() ??
            'Moderate',
      );
}

class RrResult {
  final double riskRewardRatio;
  final double potentialProfit;
  final double potentialLoss;
  final double breakEvenWinRate;
  final double expectedValue;

  const RrResult({
    required this.riskRewardRatio,
    required this.potentialProfit,
    required this.potentialLoss,
    required this.breakEvenWinRate,
    required this.expectedValue,
  });

  factory RrResult.fromJson(Map<String, dynamic> j) => RrResult(
        riskRewardRatio: _toDouble(
            j['riskRewardRatio'] ?? j['risk_reward_ratio'] ?? j['riskReward']),
        potentialProfit:
            _toDouble(j['potentialProfit'] ?? j['potential_profit'] ?? j['profit']),
        potentialLoss:
            _toDouble(j['potentialLoss'] ?? j['potential_loss'] ?? j['loss']),
        breakEvenWinRate: _toDouble(
            j['breakEvenWinRate'] ?? j['breakeven_win_rate'] ?? j['breakeven']),
        expectedValue:
            _toDouble(j['expectedValue'] ?? j['expected_value'] ?? j['ev']),
      );
}

class DrawdownResult {
  final double maxDrawdown;
  final double avgDrawdown;
  final double currentDrawdown;
  final String period;

  const DrawdownResult({
    required this.maxDrawdown,
    required this.avgDrawdown,
    required this.currentDrawdown,
    required this.period,
  });

  factory DrawdownResult.fromJson(Map<String, dynamic> j) {
    String? clean(dynamic v) => v?.toString().replaceAll('%', '').trim();
    return DrawdownResult(
      maxDrawdown: double.tryParse(
              clean(j['maxDrawdown'] ?? j['max_drawdown'] ?? j['maxDD']) ??
                  '') ??
          0,
      avgDrawdown: double.tryParse(clean(j['avgDrawdown'] ??
                  j['avg_drawdown'] ??
                  j['averageDrawdown']) ??
              '') ??
          0,
      currentDrawdown: double.tryParse(clean(
                  j['currentDrawdown'] ?? j['current_drawdown'] ?? j['drawdown']) ??
              '') ??
          0,
      period: j['period']?.toString() ?? '30d',
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiskNotifier extends ChangeNotifier {
  RiskNotifier() {
    Future.microtask(() {
      _fetchPositionSize();
      _fetchRr();
    });
  }

  final _api = ApiClient.instance;

  // inputs
  double _capital = 10000;
  double _leverage = 5;
  double _riskPercent = 2;
  double _entryPrice = 97420;
  double _stopLoss = 95000;
  double _takeProfit = 100000;
  double _winRate = 55;

  // API state
  PositionSizeResult? positionSizeResult;
  bool positionSizeLoading = false;
  String? positionSizeError;

  RrResult? rrResult;
  bool rrLoading = false;
  String? rrError;

  // debounce timers
  Timer? _posTimer;
  Timer? _rrTimer;

  // input getters
  double get capital => _capital;
  double get leverage => _leverage;
  double get riskPercent => _riskPercent;
  double get entryPrice => _entryPrice;
  double get stopLoss => _stopLoss;
  double get takeProfit => _takeProfit;
  double get winRate => _winRate;

  // client-side fallbacks
  double get localPositionSize => _capital * _riskPercent / 100;
  double get liquidationDistance => 100 / _leverage;
  double get localLiquidationPrice =>
      _entryPrice - (_entryPrice * liquidationDistance / 100);
  double get localRiskInDollars => _capital * _riskPercent / 100;

  String get riskLevel {
    if (_leverage >= 10 || _riskPercent >= 5) return 'High Risk';
    if (_leverage >= 5 || _riskPercent >= 2) return 'Moderate';
    return 'Conservative';
  }

  Color get riskColor => riskLevel == 'Conservative'
      ? AppColors.brandGreen
      : riskLevel == 'Moderate'
          ? AppColors.brandAmber
          : AppColors.brandRed;

  // ── debounced schedulers ──────────────────────────────────────────────────

  void _schedulePositionSize() {
    _posTimer?.cancel();
    _posTimer = Timer(const Duration(milliseconds: 800), _fetchPositionSize);
  }

  void _scheduleRr() {
    _rrTimer?.cancel();
    _rrTimer = Timer(const Duration(milliseconds: 800), _fetchRr);
  }

  // ── API fetches ───────────────────────────────────────────────────────────

  Future<void> _fetchPositionSize() async {
    positionSizeLoading = true;
    positionSizeError = null;
    notifyListeners();
    try {
      final res = await _api.post<Map<String, dynamic>>(
        EndPoints.riskPositionSize,
        data: {
          'accountSize': _capital,
          'riskPercent': _riskPercent,
          'leverage': _leverage,
          'entryPrice': _entryPrice,
          'stopLoss': _stopLoss,
        },
      );
      final raw = res.data ?? {};
      final inner = raw['data'];
      final payload = inner is Map<String, dynamic> ? inner : raw;
      positionSizeResult = PositionSizeResult.fromJson(payload);
      positionSizeError = null;
    } catch (_) {
      positionSizeError = 'API unavailable — showing estimated values';
    } finally {
      positionSizeLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRr() async {
    if (_takeProfit <= _entryPrice) return;
    rrLoading = true;
    rrError = null;
    notifyListeners();
    try {
      final res = await _api.post<Map<String, dynamic>>(
        EndPoints.riskRrCalculator,
        data: {
          'entryPrice': _entryPrice,
          'stopLoss': _stopLoss,
          'takeProfit': _takeProfit,
          'winRate': _winRate,
          'accountSize': _capital,
          'positionSize':
              positionSizeResult?.positionSize ?? localPositionSize,
        },
      );
      final raw = res.data ?? {};
      final inner = raw['data'];
      final payload = inner is Map<String, dynamic> ? inner : raw;
      rrResult = RrResult.fromJson(payload);
      rrError = null;
    } catch (_) {
      rrError = 'API unavailable';
    } finally {
      rrLoading = false;
      notifyListeners();
    }
  }

  // ── setters ───────────────────────────────────────────────────────────────

  void setCapital(double v) {
    if (_capital == v) return;
    _capital = v;
    notifyListeners();
    _schedulePositionSize();
    _scheduleRr();
  }

  void setLeverage(double v) {
    if (_leverage == v) return;
    _leverage = v;
    notifyListeners();
    _schedulePositionSize();
  }

  void setRiskPercent(double v) {
    if (_riskPercent == v) return;
    _riskPercent = v;
    notifyListeners();
    _schedulePositionSize();
    _scheduleRr();
  }

  void setEntryPrice(double v) {
    if (_entryPrice == v) return;
    _entryPrice = v;
    notifyListeners();
    _schedulePositionSize();
    _scheduleRr();
  }

  void setStopLoss(double v) {
    if (_stopLoss == v) return;
    _stopLoss = v;
    notifyListeners();
    _schedulePositionSize();
    _scheduleRr();
  }

  void setTakeProfit(double v) {
    if (_takeProfit == v) return;
    _takeProfit = v;
    notifyListeners();
    _scheduleRr();
  }

  void setWinRate(double v) {
    if (_winRate == v) return;
    _winRate = v;
    notifyListeners();
    _scheduleRr();
  }

  @override
  void dispose() {
    _posTimer?.cancel();
    _rrTimer?.cancel();
    super.dispose();
  }
}

final riskProvider =
    ChangeNotifierProvider.autoDispose((ref) => RiskNotifier());

// ── Drawdown params & provider ────────────────────────────────────────────────

class DrawdownParams {
  final String symbol;
  final String period;
  final String interval;

  const DrawdownParams({
    this.symbol = 'BTCUSDT',
    this.period = '30d',
    this.interval = '1d',
  });

  @override
  bool operator ==(Object other) =>
      other is DrawdownParams &&
      other.symbol == symbol &&
      other.period == period &&
      other.interval == interval;

  @override
  int get hashCode => Object.hash(symbol, period, interval);
}

final maxDrawdownProvider =
    FutureProvider.autoDispose.family<DrawdownResult, DrawdownParams>(
  (ref, params) async {
    final api = ApiClient.instance;
    final res = await api.get<Map<String, dynamic>>(
      EndPoints.riskMaxDrawdown(
        symbol: params.symbol,
        period: params.period,
        interval: params.interval,
      ),
    );
    final raw = res.data ?? {};
    final inner = raw['data'];
    final payload = inner is Map<String, dynamic> ? inner : raw;
    return DrawdownResult.fromJson(payload);
  },
);
