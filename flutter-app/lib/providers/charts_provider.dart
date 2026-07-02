import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:candlesticks/candlesticks.dart';
import '../core/remote/api_client.dart';
import '../core/remote/web_socket_baseclass.dart';
import '../core/end_points.dart';

class PatternResult {
  final String pattern;
  final String patternType;
  final int probability;
  final double target;
  final double stopLoss;
  final double riskRewardRatio;
  final String description;
  final String confidence;
  final bool volumeConfirmation;

  const PatternResult({
    required this.pattern,
    required this.patternType,
    required this.probability,
    required this.target,
    required this.stopLoss,
    required this.riskRewardRatio,
    required this.description,
    required this.confidence,
    required this.volumeConfirmation,
  });

  factory PatternResult.fromJson(Map<String, dynamic> json) => PatternResult(
    pattern: json['pattern']?.toString() ?? '—',
    patternType: json['patternType']?.toString() ?? '—',
    probability: (json['probability'] as num?)?.toInt() ?? 0,
    target: (json['target'] as num?)?.toDouble() ?? 0,
    stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 0,
    riskRewardRatio: (json['riskRewardRatio'] as num?)?.toDouble() ?? 0,
    description: json['description']?.toString() ?? '',
    confidence: json['confidence']?.toString() ?? 'medium',
    volumeConfirmation: json['volumeConfirmation'] as bool? ?? false,
  );
}

class ChartsNotifier extends ChangeNotifier {
  String _selectedCoin = 'BTC';
  String _timeframe = '4H';
  String _indicator = 'RSI';
  String _chartType = 'Candle'; // 'Candle', 'Line', 'Bar'
  
  bool _drawActive = false;
  bool _trendActive = false;
  bool _fibActive = false;
  bool _aiOverlayActive = false;
  bool _isFullscreen = false;

  List<Candle> _candles = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<KlineUpdate>? _klineSubscription;
  StreamSubscription<List<TickerUpdate>>? _tickerSubscription;
  bool _tickToggle = false;

  PatternResult? _patternResult;
  bool _patternLoading = false;
  String? _patternError;
  String? _aiMinTfMessage;

  static const _timeframeOrder = ['1m', '5m', '15m', '1H', '4H', '1D', '1W'];
  static const _minAiTfIndex = 4; // minimum: 4H

  ChartsNotifier() {
    _initSocketListener();
    loadCandles();
  }

  // Getters
  String get selectedCoin => _selectedCoin;
  String get timeframe => _timeframe;
  String get indicator => _indicator;
  String get chartType => _chartType;
  
  bool get drawActive => _drawActive;
  bool get trendActive => _trendActive;
  bool get fibActive => _fibActive;
  bool get aiOverlayActive => _aiOverlayActive;
  bool get isFullscreen => _isFullscreen;

  List<Candle> get candles => _candles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get tickToggle => _tickToggle;

  PatternResult? get patternResult => _patternResult;
  bool get patternLoading => _patternLoading;
  String? get patternError => _patternError;
  String? get aiMinTfMessage => _aiMinTfMessage;

  // Actions
  void setCoin(String coin) {
    final upper = coin.toUpperCase();
    debugPrint('ChartsNotifier: setCoin called with: $upper (previous: $_selectedCoin)');
    if (_selectedCoin == upper) return;
    _selectedCoin = upper;
    notifyListeners();
    loadCandles();
  }

  void setTimeframe(String t) {
    if (_timeframe == t) return;
    _timeframe = t;
    final idx = _timeframeOrder.indexOf(t);
    if (_aiOverlayActive && idx < _minAiTfIndex) {
      _aiOverlayActive = false;
      _patternResult = null;
      _patternError = null;
      _aiMinTfMessage = 'AI overlay requires 4H or higher timeframe';
    } else if (_aiMinTfMessage != null && idx >= _minAiTfIndex) {
      _aiMinTfMessage = null;
    }
    notifyListeners();
    loadCandles();
  }

  void setIndicator(String i) {
    if (_indicator == i) return;
    _indicator = i;
    notifyListeners();
  }

  void setChartType(String t) {
    if (_chartType == t) return;
    _chartType = t;
    if (t == 'Line') {
      if (_aiOverlayActive) {
        _aiOverlayActive = false;
        _patternResult = null;
        _patternError = null;
      }
      _aiMinTfMessage = null;
    }
    notifyListeners();
  }

  void toggleDrawActive() {
    _drawActive = !_drawActive;
    if (_drawActive) {
      _trendActive = false;
      _fibActive = false;
    }
    notifyListeners();
  }

  void toggleTrendActive() {
    _trendActive = !_trendActive;
    if (_trendActive) {
      _drawActive = false;
      _fibActive = false;
    }
    notifyListeners();
  }

  void toggleFibActive() {
    _fibActive = !_fibActive;
    if (_fibActive) {
      _drawActive = false;
      _trendActive = false;
    }
    notifyListeners();
  }

  void toggleAiOverlayActive() {
    _aiOverlayActive = !_aiOverlayActive;
    _aiMinTfMessage = null;
    if (_aiOverlayActive) {
      final idx = _timeframeOrder.indexOf(_timeframe);
      if (idx < _minAiTfIndex) {
        // Upgrade to minimum required timeframe — loadCandles will call _fetchPattern on completion
        _timeframe = _timeframeOrder[_minAiTfIndex];
        notifyListeners();
        loadCandles();
      } else {
        notifyListeners();
        _fetchPattern();
      }
    } else {
      _patternResult = null;
      _patternError = null;
      notifyListeners();
    }
  }

  Future<void> _fetchPattern() async {
    if (_candles.isEmpty) return;
    _patternLoading = true;
    _patternError = null;
    notifyListeners();
    try {
      final candleList = _candles.take(100).map((c) => {
        'timestamp': c.date.millisecondsSinceEpoch,
        'open': c.open,
        'high': c.high,
        'low': c.low,
        'close': c.close,
        'volume': c.volume,
      }).toList();

      final response = await ApiClient.instance.post(
        EndPoints.detectPattern,
        data: {
          'symbol': '${_selectedCoin}USDT',
          'timeframe': _mapTimeframe(_timeframe),
          'candles': candleList,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        _patternResult = PatternResult.fromJson(raw['data'] as Map<String, dynamic>);
      } else {
        _patternError = 'Analysis unavailable';
      }
    } catch (_) {
      _patternError = 'Analysis failed';
    } finally {
      _patternLoading = false;
      notifyListeners();
    }
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  // Fetch candlestick history
  Future<void> loadCandles() async {
    debugPrint('ChartsNotifier: loadCandles starting for $_selectedCoin on timeframe $_timeframe');
    _isLoading = true;
    _errorMessage = null;
    _candles = []; // Clear current candles to force a clean loading view in the UI
    notifyListeners();

    try {
      final symbol = '${_selectedCoin}USDT';
      final interval = _mapTimeframe(_timeframe);

      debugPrint('ChartsNotifier: Updating socket kline subscription to symbol: $symbol, interval: $interval');
      // Make sure socket subscription is updated for live ticks
      DashboardSocket.instance.subscribeWithInterval(symbol, interval);

      final url = EndPoints.klinesWithParams(
        symbol: symbol,
        interval: interval,
        limit: 100,
      );

      debugPrint('ChartsNotifier: Fetching candlestick data from: $url');
      final response = await ApiClient.instance.get(url);
      final raw = response.data;
      debugPrint('ChartsNotifier: Received response from backend for $_selectedCoin. Success: ${raw?['success']}');

      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final list = raw['data'] as List? ?? [];
        _candles = list.map((k) {
          final row = k as List;
          return Candle(
            date: DateTime.fromMillisecondsSinceEpoch(row[0] as int),
            open: double.parse(row[1].toString()),
            high: double.parse(row[2].toString()),
            low: double.parse(row[3].toString()),
            close: double.parse(row[4].toString()),
            volume: double.parse(row[5].toString()),
          );
        }).toList().reversed.toList();
        debugPrint('ChartsNotifier: Successfully parsed ${_candles.length} candles for $_selectedCoin');
        if (_aiOverlayActive) _fetchPattern();
      } else {
        _errorMessage = 'Invalid data response from backend';
        debugPrint('ChartsNotifier: Error response from backend: $raw');
      }
    } catch (e, stack) {
      _errorMessage = 'Failed to load chart data: ${e.toString()}';
      debugPrint('ChartsNotifier: Exception in loadCandles: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initSocketListener() {
    DashboardSocket.instance.connect();

    // Primary: kline stream (when server supports market:kline)
    _klineSubscription = DashboardSocket.instance.klineStream.listen((update) {
      final activeSymbol = '${_selectedCoin}USDT';
      final activeInterval = _mapTimeframe(_timeframe);

      debugPrint('ChartsNotifier: klineStream tick for ${update.symbol} (${update.interval}). Active: $activeSymbol ($activeInterval)');

      if (update.symbol.toUpperCase() == activeSymbol.toUpperCase() &&
          update.interval.toLowerCase() == activeInterval.toLowerCase()) {
        _onKlineTick(update);
      }
    });

    // Fallback: drive the latest candle's close/high/low from the ticker stream,
    // which is always active (powers the dashboard live prices).
    _tickerSubscription = DashboardSocket.instance.tickerStream.listen((tickers) {
      if (_candles.isEmpty) return;
      final activeSymbol = '${_selectedCoin.toUpperCase()}USDT';
      final match = tickers.where(
        (t) => t.symbol.toUpperCase() == activeSymbol,
      );
      if (match.isEmpty) return;
      _updateCandleFromTicker(match.first.close);
    });
  }

  void _updateCandleFromTicker(double price) {
    if (_candles.isEmpty || price <= 0) return;
    final latest = _candles.first;
    final newHigh = price > latest.high ? price : latest.high;
    final newLow = price < latest.low ? price : latest.low;
    // skip if nothing changed
    if (latest.close == price && latest.high == newHigh && latest.low == newLow) return;
    final newCandles = List<Candle>.from(_candles);
    newCandles[0] = Candle(
      date: latest.date,
      open: latest.open,
      high: newHigh,
      low: newLow,
      close: price,
      volume: latest.volume,
    );
    _candles = newCandles;
    _tickToggle = !_tickToggle;
    notifyListeners();
  }

  void _onKlineTick(KlineUpdate tick) {
    debugPrint('ChartsNotifier: _onKlineTick called. Candles length: ${_candles.length}');
    if (_candles.isEmpty) return;

    final dateMs = _candles.first.date.millisecondsSinceEpoch;
    debugPrint('ChartsNotifier: _onKlineTick - tick.openTime: ${tick.openTime}, dateMs: $dateMs');

    if (tick.openTime == dateMs) {
      debugPrint('ChartsNotifier: _onKlineTick - UPDATING existing candle at index 0');
      // Recreate list reference to force Flutter UI repaints on ticks!
      final newCandles = List<Candle>.from(_candles);
      newCandles[0] = Candle(
        date: _candles.first.date,
        open: tick.open,
        high: tick.high,
        low: tick.low,
        close: tick.close,
        volume: tick.volume,
      );
      _candles = newCandles;
      _tickToggle = !_tickToggle;
      notifyListeners();
    } else if (tick.openTime > dateMs) {
      debugPrint('ChartsNotifier: _onKlineTick - INSERTING new candle at index 0');
      // Recreate list reference to force Flutter UI repaints on new candles!
      final newCandles = List<Candle>.from(_candles);
      newCandles.insert(
        0,
        Candle(
          date: DateTime.fromMillisecondsSinceEpoch(tick.openTime),
          open: tick.open,
          high: tick.high,
          low: tick.low,
          close: tick.close,
          volume: tick.volume,
        ),
      );
      if (newCandles.length > 100) {
        newCandles.removeLast();
      }
      _candles = newCandles;
      _tickToggle = !_tickToggle;
      notifyListeners();
    } else {
      debugPrint('ChartsNotifier: _onKlineTick - tick.openTime (${tick.openTime}) is older than dateMs ($dateMs), ignoring.');
    }
  }

  String _mapTimeframe(String tf) {
    switch (tf) {
      case '1H': return '1h';
      case '4H': return '4h';
      case '1D': return '1d';
      case '1W': return '1w';
      default: return tf;
    }
  }

  @override
  void dispose() {
    _klineSubscription?.cancel();
    _tickerSubscription?.cancel();
    super.dispose();
  }
}

final chartsProvider = ChangeNotifierProvider(
  (ref) => ChartsNotifier(),
);
