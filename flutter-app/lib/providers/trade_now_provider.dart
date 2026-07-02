import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/trade_now/trade_now_repo_impl.dart';
import '../core/remote/data/trade_now/models/trade_now_models.dart';

final _repo = TradeNowRepoImpl();

/// Fetches all Trade Now endpoints in parallel for [symbol] (e.g. "BTC").
/// Futures endpoints are guarded — a spot-only coin returns empty fallbacks
/// instead of crashing the whole provider.
final tradeNowProvider =
    FutureProvider.autoDispose.family<TradeNowData, String>((ref, symbol) async {
  Future<T> guard<T>(Future<T> f, T fallback) async {
    try {
      return await f;
    } catch (_) {
      return fallback;
    }
  }

  final results = await Future.wait([
    _repo.fetchSignal(symbol),
    guard(_repo.fetchSentiment(symbol), SentimentData.empty),
    guard(_repo.fetchOpenInterest(symbol), OpenInterestData.empty),
    guard(_repo.fetchLongShort(symbol), LongShortData.empty),
    guard(_repo.fetchLiquidations(symbol), LiquidationData.empty),
    guard(_repo.fetchFundingRate(symbol), FundingRateInfo.empty),
    guard(_repo.fetchHistory(symbol), <HistoricalSetup>[]),
  ]);

  final signal = results[0] as SignalData;
  final metrics = signal.rawMetrics;

  // Use signal metrics as fallback when separate endpoints fail or return defaults.
  var longShort = results[3] as LongShortData;
  if (longShort.ratio == 1.0 && longShort.label == 'Balanced' && metrics.isNotEmpty) {
    longShort = LongShortData.fromMetrics(metrics);
  }

  var liquidations = results[4] as LiquidationData;
  if (liquidations.unavailable && metrics.isNotEmpty) {
    liquidations = LiquidationData.fromMetrics(metrics);
  }

  return TradeNowData(
    signal: signal,
    sentiment: results[1] as SentimentData,
    openInterest: results[2] as OpenInterestData,
    longShort: longShort,
    liquidations: liquidations,
    funding: results[5] as FundingRateInfo,
    history: results[6] as List<HistoricalSetup>,
  );
});