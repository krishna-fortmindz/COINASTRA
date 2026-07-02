import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/coin_selector.dart';
import '../../core/remote/data/trade_now/models/trade_now_models.dart';
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
                        ref.read(selectedCoinProvider.notifier).state = c,
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
          _buildLevelsCard(signal),
          const SizedBox(height: 16),
          _buildReasoningCard(signal),
        ] else ...[
          LayoutBuilder(builder: (_, c) {
            if (c.maxWidth < 700) {
              return Column(children: [
                _buildMetricsGrid(data),
                const SizedBox(height: 16),
                _buildLevelsCard(signal),
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildMetricsGrid(data)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildLevelsCard(signal)),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildReasoningCard(signal),
          if (data.history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHistoricalSetups(data.history),
          ],
          const SizedBox(height: 16),
          CoinFundingOiCard(coin: _selectedCoin),
          // const SizedBox(height: 16),
          // CoinLiquidationsCard(coin: _selectedCoin),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
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
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ConfidenceRing(confidence: s.confidence, color: color),
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

  Widget _buildLevelsCard(SignalData s) {
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

  Widget _buildReasoningCard(SignalData s) {
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
