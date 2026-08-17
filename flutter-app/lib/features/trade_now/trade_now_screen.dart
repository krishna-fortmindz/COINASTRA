import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/coin_selector.dart';
import '../../core/remote/data/trade_now/models/trade_now_models.dart';
import '../../core/remote/data/alerts/alerts_repo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trade_now_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/selected_coin_provider.dart';
import '../../core/widgets/coin_data_sections.dart';

class TradeNowScreen extends ConsumerStatefulWidget {
  const TradeNowScreen({super.key});

  @override
  ConsumerState<TradeNowScreen> createState() => _TradeNowScreenState();
}

class _TradeNowScreenState extends ConsumerState<TradeNowScreen> {
  String get _selectedCoin => ref.watch(selectedCoinProvider);

  Color _verdictColor(VerdictType t) {
    switch (t) {
      case VerdictType.bullish:
        return AppColors.brandGreen;
      case VerdictType.bearish:
        return AppColors.brandRed;
      case VerdictType.caution:
        return AppColors.brandAmber;
      case VerdictType.neutral:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tradeNowProvider(_selectedCoin));
    final tickerAsync = ref.watch(tickerProvider);
    final livePrice = tickerAsync.maybeWhen(
      data: (map) => map['${_selectedCoin}USDT']?.close,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  CoinSelector(
                    selected: _selectedCoin,
                    onChanged: (c) =>
                        ref.read(selectedCoinProvider.notifier).set(c),
                  ),
                  const SizedBox(height: 20),
                  async.when(
                    loading: _buildShimmer,
                    error: (e, _) => _buildError(),
                    data: (data) => _buildContent(data, livePrice),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TradeNowData data, double? livePrice) {
    final signal = data.signal;

    if (signal.coinNotSupported) {
      return _buildUnsupportedCoin();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerdictCard(signal, livePrice),
        const SizedBox(height: 16),
        if (!signal.futuresAvailable) ...[
          _buildSpotOnlyNotice(),
          const SizedBox(height: 16),
          _buildLevelsCard(signal, _selectedCoin),
          const SizedBox(height: 16),
          _buildAiInsightCard(signal),
        ] else ...[
          if (signal.chartUrl.isNotEmpty) ...[
            _buildChartCard(signal.chartUrl),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(builder: (_, c) {
            if (c.maxWidth < 700) {
              return Column(children: [
                _buildMetricsGrid(data),
                const SizedBox(height: 16),
                _buildLevelsCard(signal, _selectedCoin),
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildMetricsGrid(data)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildLevelsCard(signal, _selectedCoin)),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildIndicatorsCard(signal),
          const SizedBox(height: 16),
          _buildAiInsightCard(signal),
          if (data.history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHistoricalSetups(data.history),
          ],
          const SizedBox(height: 16),
          CoinFundingOiCard(coin: _selectedCoin),
        ],
      ],
    );
  }

  Widget _buildUnsupportedCoin() {
    return GlassCard(
      borderColor: AppColors.brandAmber.withAlpha(40),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.brandAmber, size: 36),
            const SizedBox(height: 12),
            Text(
              '$_selectedCoin is not a recognized trading pair',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try BTC, ETH, SOL, BNB, XRP, DOGE, or any Binance-listed coin.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandBlue.withAlpha(35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.brandBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Spot-only coin — futures metrics (OI, funding rate, L/S ratio) are not available. Trade levels use S/R + Fibonacci.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.brandBlue, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.gradientGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trade Now?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
              Text(
                  'AI signal aggregator · Funding · OI · L/S Ratio · Sentiment',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        const NeonBadge(
            label: 'LIVE', color: AppColors.brandGreen, icon: Icons.circle),
      ],
    );
  }

  Widget _buildVerdictCard(SignalData s, double? livePrice) {
    final color = _verdictColor(s.verdictType);
    final displayPrice = livePrice != null
        ? (livePrice >= 1000
            ? '\$${livePrice.toStringAsFixed(0)}'
            : '\$${livePrice.toStringAsFixed(4)}')
        : s.formattedPrice;

    final regimeColor = s.marketRegime == 'bullish'
        ? AppColors.brandGreen
        : s.marketRegime == 'bearish'
            ? AppColors.brandRed
            : AppColors.brandAmber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.verdictIcon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.displayVerdictLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: color,
                              )),
                        ),
                        if (livePrice != null)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.brandGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('$_selectedCoin/USDT ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            )),
                        Text(displayPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: livePrice != null
                                  ? AppColors.brandGreen
                                  : Colors.white,
                              fontFamily: 'JetBrainsMono',
                            )),
                      ],
                    ),
                    if (s.marketRegime.isNotEmpty || s.setupScoreLong > 0) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (s.marketRegime.isNotEmpty)
                            _SmallBadge(
                              label: s.marketRegime.toUpperCase(),
                              color: regimeColor,
                            ),
                          if (s.setupScoreLong > 0 || s.setupScoreShort > 0)
                            _SmallBadge(
                              label: 'L ${s.setupScoreLong} / S ${s.setupScoreShort}',
                              color: AppColors.brandPurple,
                              icon: Icons.analytics_outlined,
                            ),
                          if (s.leverage.suggestedLeverage > 0)
                            _SmallBadge(
                              label: '${s.leverage.suggestedLeverage}x',
                              color: AppColors.brandCyan,
                              icon: Icons.speed_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _ConfidenceRing(confidence: s.confidence, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(TradeNowData d) {
    final fundingBadgeColor =
        d.funding.level == 'High' || d.funding.level == 'Very High'
            ? AppColors.brandRed
            : d.funding.level == 'Elevated'
                ? AppColors.brandAmber
                : AppColors.brandGreen;

    final oiBadgeColor = d.openInterest.changeLabel == 'Surging' ||
            d.openInterest.changeLabel == 'Rising'
        ? AppColors.brandAmber
        : AppColors.brandGreen;

    final lsBadgeColor = d.longShort.label.contains('Crowded')
        ? AppColors.brandRed
        : d.longShort.label == 'Short-Heavy'
            ? AppColors.brandGreen
            : AppColors.textMuted;

    // final liqColor = d.liquidations.unavailable
    //     ? AppColors.textMuted
    //     : d.liquidations.capitalizedSide == 'Below'
    //         ? AppColors.brandAmber
    //         : AppColors.brandGreen;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _MetricTile(
              label: 'Funding Rate',
              value: d.funding.formatted,
              badge: d.funding.level,
              badgeColor: fundingBadgeColor,
              icon: Icons.swap_horiz_rounded,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricTile(
              label: 'OI Change',
              value: d.openInterest.formattedChange,
              badge: d.openInterest.changeLabel,
              badgeColor: oiBadgeColor,
              icon: Icons.trending_up_rounded,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _MetricTile(
              label: 'Long/Short Ratio',
              value: d.longShort.formattedRatio,
              badge: d.longShort.label,
              badgeColor: lsBadgeColor,
              icon: Icons.people_rounded,
            )),
            // const SizedBox(width: 12),
            // Expanded(
            //     child: _MetricTile(
            //   label: 'Liq Wall',
            //   value: d.liquidations.unavailable
            //       ? 'Unavailable'
            //       : d.liquidations.formattedWall,
            //   badge: d.liquidations.unavailable
            //       ? 'No Data'
            //       : d.liquidations.capitalizedSide,
            //   badgeColor: liqColor,
            //   icon: Icons.local_fire_department_rounded,
            // )),
          ],
        ),
        const SizedBox(height: 12),
        _SentimentBar(value: d.sentiment.score, label: d.sentiment.label),
      ],
    );
  }

  Widget _buildLevelsCard(SignalData s, String coin) {
    final showNoLevelsNotice =
        s.entry == '—' || s.entry == '\$0–\$0' || s.entry == '\$0.00–\$0.00';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trade Levels',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 16),
          if (showNoLevelsNotice)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandAmber.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandAmber.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12, color: AppColors.brandAmber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trade levels not available for this coin. Try BTC, ETH, SOL, BNB, or XRP.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.brandAmber,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          _LevelRow('Entry Zone', s.entry, AppColors.brandBlue),
          const SizedBox(height: 10),
          _LevelRow('Take Profit', s.takeProfit, AppColors.brandGreen),
          const SizedBox(height: 10),
          _LevelRow('Stop Loss', s.stopLoss, AppColors.brandRed),
          const SizedBox(height: 10),
          _LevelRow('Risk/Reward', s.riskReward, AppColors.brandAmber),
          if (s.keyLevels.nearestSupport > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            const Text('Key Levels',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _LevelRow('Support', SignalData.formatPriceStatic(s.keyLevels.nearestSupport), AppColors.brandGreen),
            const SizedBox(height: 8),
            _LevelRow('Resistance', SignalData.formatPriceStatic(s.keyLevels.nearestResistance), AppColors.brandRed),
            const SizedBox(height: 8),
            _LevelRow('Fib 38.2%', SignalData.formatPriceStatic(s.keyLevels.fib382), AppColors.brandPurple),
            const SizedBox(height: 8),
            _LevelRow('Fib 50%', SignalData.formatPriceStatic(s.keyLevels.fib50), AppColors.brandPurple),
            const SizedBox(height: 8),
            _LevelRow('Fib 61.8%', SignalData.formatPriceStatic(s.keyLevels.fib618), AppColors.brandPurple),
          ],
          const SizedBox(height: 16),
          _SetAlertButton(signal: s, coin: coin),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: AppColors.textDisabled),
              SizedBox(width: 6),
              Expanded(
                child: Text('Levels are AI-generated. Not financial advice.',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textDisabled,
                        height: 1.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String chartUrl) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          chartUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 200,
              color: AppColors.bgCard,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildIndicatorsCard(SignalData s) {
    final ind = s.indicators;
    if (ind.rsi == 50 && ind.macdHistogram == 0 && ind.bbPercentB == 50) {
      return const SizedBox.shrink();
    }

    final rsiColor = ind.rsi >= 70
        ? AppColors.brandRed
        : ind.rsi <= 30
            ? AppColors.brandGreen
            : ind.rsi >= 60
                ? AppColors.brandGreen
                : ind.rsi <= 40
                    ? AppColors.brandAmber
                    : AppColors.textMuted;

    final macdColor = ind.macdHistogram > 0.000001
        ? AppColors.brandGreen
        : ind.macdHistogram < -0.000001
            ? AppColors.brandRed
            : AppColors.textMuted;

    final bbColor = ind.bbPercentB >= 80
        ? AppColors.brandRed
        : ind.bbPercentB <= 20
            ? AppColors.brandGreen
            : AppColors.textMuted;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Technical Indicators',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _IndicatorItem(
                  label: 'RSI (14)',
                  value: ind.rsi.toStringAsFixed(1),
                  badge: ind.rsiLabel,
                  color: rsiColor,
                  barValue: ind.rsi / 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IndicatorItem(
                  label: 'MACD Hist.',
                  value: ind.macdHistogram.toStringAsFixed(4),
                  badge: ind.macdLabel,
                  color: macdColor,
                  barValue: ((ind.macdHistogram.clamp(-0.01, 0.01) + 0.01) / 0.02),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IndicatorItem(
                  label: 'BB %B',
                  value: '${ind.bbPercentB.toStringAsFixed(1)}%',
                  badge: ind.bbPercentB >= 80
                      ? 'Near Upper'
                      : ind.bbPercentB <= 20
                          ? 'Near Lower'
                          : 'Mid Band',
                  color: bbColor,
                  barValue: ind.bbPercentB / 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(SignalData s) {
    final insight = s.aiInsight;
    final hasInsight = insight.primaryReason.isNotEmpty ||
        insight.nearTermOutlook.isNotEmpty;

    if (!hasInsight) {
      return GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.gradientGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Reasoning',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreen,
                      )),
                  const SizedBox(height: 6),
                  Text(
                      s.reasoning.isEmpty
                          ? 'No reasoning available.'
                          : s.reasoning,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.6,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final riskColor = insight.riskLevel == 'high'
        ? AppColors.brandRed
        : insight.riskLevel == 'medium'
            ? AppColors.brandAmber
            : AppColors.brandGreen;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.black, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('AI Insight',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor.withAlpha(50)),
                ),
                child: Text(
                  '${insight.riskLevel.toUpperCase()} RISK',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (insight.primaryReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InsightSection(
              icon: Icons.trending_flat_rounded,
              label: 'Primary Signal',
              text: insight.primaryReason,
              color: AppColors.brandBlue,
            ),
          ],
          if (insight.secondaryReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightSection(
              icon: Icons.bar_chart_rounded,
              label: 'Technical View',
              text: insight.secondaryReason,
              color: AppColors.brandPurple,
            ),
          ],
          if (insight.nearTermOutlook.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightSection(
              icon: Icons.access_time_rounded,
              label: 'Near-Term Outlook',
              text: insight.nearTermOutlook,
              color: AppColors.brandAmber,
            ),
          ],
          if (insight.fundamentalContext.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightSection(
              icon: Icons.layers_rounded,
              label: 'Fundamental Context',
              text: insight.fundamentalContext,
              color: AppColors.brandCyan,
            ),
          ],
          if (s.reasoning.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            const Text('Signal Factors',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...s.reasoning
                .split(RegExp(r'\. (?=[A-Z])'))
                .where((r) => r.trim().isNotEmpty)
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('·  ',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDisabled,
                                  height: 1.6)),
                          Expanded(
                            child: Text(
                              r.trim().endsWith('.')
                                  ? r.trim()
                                  : '${r.trim()}.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoricalSetups(List<HistoricalSetup> setups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historical Setups Like This',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
        const SizedBox(height: 10),
        ...setups.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.positive
                            ? AppColors.brandGreen
                            : AppColors.brandRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 3),
                          Text(s.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1.4,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(s.outcome,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: s.positive
                              ? AppColors.brandGreen
                              : AppColors.brandRed,
                          fontFamily: 'JetBrainsMono',
                        )),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.bgCard,
          highlightColor: AppColors.bgTertiary,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
              2,
              (_) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Shimmer.fromColors(
                        baseColor: AppColors.bgCard,
                        highlightColor: AppColors.bgTertiary,
                        child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  )),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
              2,
              (_) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Shimmer.fromColors(
                        baseColor: AppColors.bgCard,
                        highlightColor: AppColors.bgTertiary,
                        child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  )),
        ),
      ],
    );
  }

  Widget _buildError() {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.brandRed, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Could not load signal data',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(tradeNowProvider(_selectedCoin)),
            child: const Text('Retry',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandGreen,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ConfidenceRing extends StatelessWidget {
  final int confidence;
  final Color color;
  const _ConfidenceRing({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (confidence / 100).clamp(0.0, 1.0),
          color: color,
          trackColor: AppColors.borderSubtle,
          strokeWidth: 5,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$confidence%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'JetBrainsMono',
                  height: 1.1,
                ),
              ),
              const Text(
                'conf.',
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.textMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _MetricTile extends StatelessWidget {
  final String label, value, badge;
  final Color badgeColor;
  final IconData icon;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'JetBrainsMono',
              )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                  letterSpacing: 0.3,
                )),
          ),
        ],
      ),
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final int value;
  final String label;
  const _SentimentBar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = value > 65
        ? AppColors.brandGreen
        : value > 45
            ? AppColors.brandAmber
            : AppColors.brandRed;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mood_rounded,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Text('News & Social Sentiment',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  )),
              const Spacer(),
              Text('$value / 100',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'JetBrainsMono',
                  )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _SmallBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}

class _IndicatorItem extends StatelessWidget {
  final String label, value, badge;
  final Color color;
  final double barValue;
  const _IndicatorItem({
    required this.label,
    required this.value,
    required this.badge,
    required this.color,
    required this.barValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'JetBrainsMono',
            )),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: barValue.clamp(0.0, 1.0),
            backgroundColor: AppColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(badge,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              )),
        ),
      ],
    );
  }
}

class _InsightSection extends StatelessWidget {
  final IconData icon;
  final String label, text;
  final Color color;
  const _InsightSection({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  )),
            ],
          ),
          const SizedBox(height: 5),
          Text(text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.55,
              )),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _LevelRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'JetBrainsMono',
            )),
      ],
    );
  }
}

// ── Set Alert Button ─────────────────────────────────────────────────────────

class _SetAlertButton extends ConsumerStatefulWidget {
  final SignalData signal;
  final String coin;

  const _SetAlertButton({required this.signal, required this.coin});

  @override
  ConsumerState<_SetAlertButton> createState() => _SetAlertButtonState();
}

class _SetAlertButtonState extends ConsumerState<_SetAlertButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _hasLevels =>
      widget.signal.rawTakeProfit > 0 || widget.signal.rawStopLoss > 0;

  String get _direction {
    switch (widget.signal.verdictType) {
      case VerdictType.bearish:
        return 'short';
      default:
        return 'long';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLevels) return const SizedBox.shrink();

    final isLoggedIn = ref.watch(authProvider);

    if (!isLoggedIn) {
      return _buildLoginPrompt();
    }

    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final t = _pulse.value;
          final c1 = Color.lerp(
              const Color(0xFF00C896), const Color(0xFF00FF9A), t)!;
          final c2 = Color.lerp(
              const Color(0xFF00A876), const Color(0xFF00D890), t)!;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [c1, c2, c1],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 255, 136, 0.15 + t * 0.35),
                  blurRadius: 14 + t * 10,
                  spreadRadius: t * 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _loading ? null : _showConfirmSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active_rounded,
                            size: 18, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Add Alert · TP / SL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF00C896).withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: const Color(0xFF00C896),
        ),
        onPressed: () => _showLoginDialog(),
        icon: const Icon(Icons.lock_outline_rounded, size: 14),
        label: const Text(
          'Sign in to set price alerts',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogCtx) => Dialog(
        backgroundColor: const Color(0xFF141519),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C896), Color(0xFF00A876)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Colors.black, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign In Required',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a free account to set TP & SL price alerts and receive push notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    html.window.location.assign('/auth/login');
                  },
                  child: const Text(
                    'Sign In / Create Account',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmSheet() {
    final s = widget.signal;
    final coin = widget.coin;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141519),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Color(0xFF00C896), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Add Alert · TP / SL — $coin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SheetRow('Direction', _direction.toUpperCase(),
                _direction == 'long' ? AppColors.brandGreen : AppColors.brandRed),
            const SizedBox(height: 10),
            _SheetRow('Entry (current)', s.formattedPrice, AppColors.brandBlue),
            if (s.rawTakeProfit > 0) ...[
              const SizedBox(height: 10),
              _SheetRow('Take Profit', s.takeProfit, AppColors.brandGreen),
            ],
            if (s.rawStopLoss > 0) ...[
              const SizedBox(height: 10),
              _SheetRow('Stop Loss', s.stopLoss, AppColors.brandRed),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _createAlert();
                },
                child: const Text(
                  'Confirm & Set Alert',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAlert() async {
    setState(() => _loading = true);
    try {
      await AlertsRepo.instance.createAlert(
        symbol: '${widget.coin}USDT',
        entryPrice: widget.signal.price,
        takeProfitPrice: widget.signal.rawTakeProfit,
        stopLossPrice: widget.signal.rawStopLoss,
        direction: _direction,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF00C896), size: 18),
                const SizedBox(width: 10),
                Text(
                  'Alert set for ${widget.coin} · TP ${widget.signal.takeProfit} / SL ${widget.signal.stopLoss}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1D24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set alert: $e',
                style: const TextStyle(fontSize: 13, color: Colors.white)),
            backgroundColor: AppColors.brandRed.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SheetRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'JetBrainsMono',
            )),
      ],
    );
  }
}
