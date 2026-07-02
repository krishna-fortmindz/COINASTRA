import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/coin_selector.dart';
import '../../providers/charts_provider.dart';
import '../../providers/ai_analysis_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/selected_coin_provider.dart';

const _timeframes = ['1m', '5m', '15m', '1H', '4H', '1D', '1W'];
const _indicators = ['RSI', 'MACD', 'EMA', 'Volume', 'Bollinger'];

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(chartsProvider);

    // Sync chartsProvider with global coin (handles global search + first build after navigation)
    final globalCoin = ref.watch(selectedCoinProvider);
    if (n.selectedCoin != globalCoin) {
      Future.microtask(() => ref.read(chartsProvider).setCoin(globalCoin));
    }
    ref.listen<String>(selectedCoinProvider, (_, coin) {
      ref.read(chartsProvider).setCoin(coin);
      ref.read(aiAnalysisProvider).selectCoin(coin);
    });

    // Fullscreen Layout takes over the entire screen area
    if (n.isFullscreen) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Expanded(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const _ChartToolbar(),
                      const Expanded(child: _SelectedChart()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default split screen layout with Header, Main Chart and Indicator Panel
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChartHeader(),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: GlassCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    const _ChartToolbar(),
                    const Expanded(child: _SelectedChart()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: GlassCard(
                child: _IndicatorPanel(
                  indicator: n.indicator,
                  candles: n.candles,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartHeader extends ConsumerWidget {
  const _ChartHeader();

  Widget _timeframeButtons(WidgetRef ref, String currentTf) => Row(
        mainAxisSize: MainAxisSize.min,
        children: _timeframes
            .map((t) => GestureDetector(
                  onTap: () => ref.read(chartsProvider).setTimeframe(t),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: currentTf == t
                          ? AppColors.brandGreen.withAlpha(20)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: currentTf == t
                            ? AppColors.brandGreen.withAlpha(60)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(t,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: currentTf == t
                              ? AppColors.brandGreen
                              : AppColors.textMuted,
                        )),
                  ),
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(chartsProvider);
    final tickerAsync = ref.watch(tickerProvider);
    final livePrice = tickerAsync.maybeWhen(
      data: (map) => map['${n.selectedCoin}USDT']?.close,
      orElse: () => null,
    );

    return LayoutBuilder(builder: (_, c) {
      final isMobile = c.maxWidth < 700;
      final coinSelector = CoinSelector(
        selected: n.selectedCoin,
        onChanged: (coin) => ref.read(selectedCoinProvider.notifier).state = coin,
      );
      final priceWidget = livePrice != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandGreen.withAlpha(40)),
              ),
              child: Text(
                livePrice >= 1000
                    ? '\$${livePrice.toStringAsFixed(0)}'
                    : '\$${livePrice.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandGreen,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            )
          : const SizedBox.shrink();

      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: coinSelector),
              const SizedBox(width: 8),
              priceWidget,
            ]),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _timeframeButtons(ref, n.timeframe),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(flex: 2, child: coinSelector),
          const SizedBox(width: 12),
          priceWidget,
          const SizedBox(width: 16),
          _timeframeButtons(ref, n.timeframe),
        ],
      );
    });
  }
}

class _ChartToolbar extends ConsumerWidget {
  const _ChartToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(chartsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolBtn(
                    icon: Icons.show_chart_rounded,
                    label: 'Line',
                    active: n.chartType == 'Line',
                    onTap: () => ref.read(chartsProvider).setChartType('Line'),
                  ),
                  _ToolBtn(
                    icon: Icons.candlestick_chart_rounded,
                    label: 'Candle',
                    active: n.chartType == 'Candle',
                    onTap: () =>
                        ref.read(chartsProvider).setChartType('Candle'),
                  ),
                  _ToolBtn(
                    icon: Icons.bar_chart_rounded,
                    label: 'Bar',
                    active: n.chartType == 'Bar',
                    onTap: () => ref.read(chartsProvider).setChartType('Bar'),
                  ),
                  const SizedBox(width: 16),
                  _ToolBtn(
                    icon: Icons.draw_rounded,
                    label: 'Draw',
                    active: n.drawActive,
                    onTap: () => ref.read(chartsProvider).toggleDrawActive(),
                  ),
                  _ToolBtn(
                    icon: Icons.horizontal_rule_rounded,
                    label: 'Trend',
                    active: n.trendActive,
                    onTap: () => ref.read(chartsProvider).toggleTrendActive(),
                  ),
                  _ToolBtn(
                    icon: Icons.grid_on_rounded,
                    label: 'Fib',
                    active: n.fibActive,
                    onTap: () => ref.read(chartsProvider).toggleFibActive(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (n.chartType != 'Line') ...[
            GestureDetector(
              onTap: () => ref.read(chartsProvider).toggleAiOverlayActive(),
              child: NeonBadge(
                label: n.aiOverlayActive ? 'AI Overlay ON' : 'AI Overlay OFF',
                color: n.aiOverlayActive
                    ? AppColors.brandGreen
                    : AppColors.textMuted,
                icon: Icons.psychology_rounded,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _ToolBtn(
            icon: n.isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            label: n.isFullscreen ? 'Exit' : 'Full',
            active: n.isFullscreen,
            onTap: () => ref.read(chartsProvider).toggleFullscreen(),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:
              active ? AppColors.brandGreen.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? AppColors.brandGreen : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.brandGreen : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _SelectedChart extends ConsumerWidget {
  const _SelectedChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(chartsProvider);

    if (n.isLoading && n.candles.isEmpty) {
      return const _ChartLoadingView();
    }

    if (n.errorMessage != null && n.candles.isEmpty) {
      return _ChartErrorView(
        message: n.errorMessage!,
        onRetry: () => ref.read(chartsProvider).loadCandles(),
      );
    }

    if (n.candles.length <= 1) {
      return const Center(
        child: Text(
          'No candle data available.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding:
                const EdgeInsets.only(top: 40, bottom: 8, left: 8, right: 8),
            child: _buildChart(context, n),
          ),
        ),

        // AI min-timeframe warning card
        if (!n.aiOverlayActive && n.aiMinTfMessage != null)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withAlpha(230),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.amber),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      n.aiMinTfMessage!,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // AI Pattern Box Overlay
        if (n.aiOverlayActive)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withAlpha(230),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandGreen.withAlpha(40)),
              ),
              child: n.patternLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10, height: 10,
                          child: CircularProgressIndicator(
                            color: AppColors.brandGreen, strokeWidth: 1.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Analyzing pattern…',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    )
                  : n.patternError != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.brandRed),
                            const SizedBox(width: 6),
                            Text(n.patternError!,
                              style: const TextStyle(
                                fontSize: 10, color: AppColors.brandRed)),
                          ],
                        )
                      : n.patternResult != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('AI Pattern Detected',
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w700,
                                        color: AppColors.brandGreen, letterSpacing: 0.5,
                                      )),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandGreen.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('${n.patternResult!.probability}%',
                                        style: const TextStyle(
                                          fontSize: 9, fontWeight: FontWeight.w700,
                                          color: AppColors.brandGreen,
                                        )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${n.selectedCoin} · ${n.patternResult!.pattern}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: \$${n.patternResult!.target.toStringAsFixed(2)} · Stop: \$${n.patternResult!.stopLoss.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                                if (n.patternResult!.volumeConfirmation) ...[
                                  const SizedBox(height: 2),
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                        size: 10, color: AppColors.brandGreen),
                                      SizedBox(width: 3),
                                      Text('Volume confirmed',
                                        style: TextStyle(fontSize: 9, color: AppColors.brandGreen)),
                                    ],
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
            ),
          ),

        // Drawing banner when drawing modes are toggled
        if (n.drawActive || n.trendActive || n.fibActive)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandGreen.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.brandGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      n.drawActive
                          ? 'Freehand drawing mode active. Touch and drag on the chart area to draw.'
                          : n.trendActive
                              ? 'Trendline tool active. Tap two points on the chart to draw a line.'
                              : 'Fibonacci retracement tool active. Select swing high and low points.',
                      style: const TextStyle(
                          color: AppColors.brandGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (n.drawActive)
                        ref.read(chartsProvider).toggleDrawActive();
                      if (n.trendActive)
                        ref.read(chartsProvider).toggleTrendActive();
                      if (n.fibActive)
                        ref.read(chartsProvider).toggleFibActive();
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.brandGreen, size: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, ChartsNotifier n) {
    switch (n.chartType) {
      case 'Line':
        return _buildLineChart(n);
      case 'Bar':
        return _buildBarChart(n);
      case 'Candle':
      default:
        return _buildCandleChart(n);
    }
  }

  Widget _buildCandleChart(ChartsNotifier n) {
    // The candlesticks package's CandleStickRenderObject only calls
    // markNeedsPaint() when: (a) candle list length changes, or
    // (b) _index <= 0 AND the latest close price changed.
    // It ignores high/low/open/volume changes and doesn't repaint
    // if the user has scrolled at all (_index > 0).
    //
    // Workaround: alternate bullColor/bearColor alpha between 255 and 254
    // on every tick. The render object's color setters compare Color.value
    // and call markNeedsPaint() when they differ. Alpha 254 vs 255 is
    // visually imperceptible but guarantees a repaint on every tick.
    //
    // NOTE: withOpacity(0.999) does NOT work because
    // (0.999 * 255).round() == 255, producing the same Color.value.
    final bullColor = n.tickToggle
        ? AppColors.brandGreen
        : AppColors.brandGreen.withAlpha(254);
    final bearColor = n.tickToggle
        ? AppColors.brandRed
        : AppColors.brandRed.withAlpha(254);

    return Candlesticks(
      key: ValueKey('${n.selectedCoin}_${n.timeframe}_Candle'),
      candles: n.candles,
      style: CandleSticksStyle.dark(
        chartBackgroundColor: Colors.transparent,
        gridLineColor: AppColors.borderSubtle,
        axisTextColor: AppColors.textMuted,
        candleBullColor: bullColor,
        candleBearColor: bearColor,
        volumeBullColor: bullColor.withAlpha(70),
        volumeBearColor: bearColor.withAlpha(69),
      ),
    );
  }

  Widget _buildLineChart(ChartsNotifier n) {
    final closes = n.candles.map((c) => c.close).toList();
    final rawMin = closes.reduce(math.min);
    final rawMax = closes.reduce(math.max);
    final range = rawMax - rawMin;
    // pad by 0.2 % of the mid-price so interval is never 0 on flat candles
    final pad = range > 0 ? range * 0.1 : rawMax * 0.002;
    final double minY = rawMin - pad;
    final double maxY = rawMax + pad;
    final double safeRange = maxY - minY;
    final double hInterval = safeRange / 5;
    final double titleInterval = safeRange / 4;

    final reversedList = n.candles.reversed.toList();
    final spots = reversedList.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.close);
    }).toList();

    return LineChart(
      key: ValueKey('${n.selectedCoin}_${n.timeframe}_${n.tickToggle}_Line'),
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: hInterval,
          getDrawingHorizontalLine: (val) => const FlLine(
            color: AppColors.borderSubtle,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: titleInterval,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                final label = val >= 1000
                    ? '\$${(val / 1000).toStringAsFixed(1)}k'
                    : '\$${val.toStringAsFixed(2)}';
                return Text(
                  label,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgCard.withAlpha(235),
            tooltipBorder: const BorderSide(color: AppColors.borderSubtle),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final candle = reversedList[spot.spotIndex];
                final dateStr =
                    candle.date.toLocal().toString().substring(11, 16);
                return LineTooltipItem(
                  '${n.selectedCoin}/USDT\n\$${spot.y.toStringAsFixed(2)}\nTime: $dateStr',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                );
              }).toList();
            },
          ),
        ),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.brandGreen,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brandGreen.withAlpha(50),
                  AppColors.brandGreen.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ChartsNotifier n) {
    final double minY =
        n.candles.map((c) => math.min(c.open, c.close)).reduce(math.min) *
            0.998;
    final double maxY =
        n.candles.map((c) => math.max(c.open, c.close)).reduce(math.max) *
            1.002;

    final reversedList = n.candles.reversed.toList();
    final barGroups = reversedList.asMap().entries.map((entry) {
      final index = entry.key;
      final candle = entry.value;
      final isBullish = candle.close >= candle.open;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: candle.close,
            fromY: candle.open,
            color: isBullish ? AppColors.brandGreen : AppColors.brandRed,
            width: 3,
            borderRadius: BorderRadius.circular(1),
          ),
        ],
      );
    }).toList();

    return BarChart(
      key: ValueKey('${n.selectedCoin}_${n.timeframe}_Bar'),
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (val) => const FlLine(
            color: AppColors.borderSubtle,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (val, meta) {
                return Text(
                  '\$${val.toStringAsFixed(0)}',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgCard.withAlpha(235),
            tooltipBorder: const BorderSide(color: AppColors.borderSubtle),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final candle = reversedList[groupIndex];
              final isBull = candle.close >= candle.open;
              final dateStr =
                  candle.date.toLocal().toString().substring(11, 16);
              return BarTooltipItem(
                '${n.selectedCoin}/USDT ($dateStr)\n'
                'O: \$${candle.open.toStringAsFixed(2)}\n'
                'C: \$${candle.close.toStringAsFixed(2)}\n'
                'H: \$${candle.high.toStringAsFixed(2)}\n'
                'L: \$${candle.low.toStringAsFixed(2)}',
                TextStyle(
                  color: isBull ? AppColors.brandGreen : AppColors.brandRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        minY: minY,
        maxY: maxY,
        barGroups: barGroups,
      ),
    );
  }
}

class _ChartLoadingView extends StatelessWidget {
  const _ChartLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.brandGreen,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching real-time market data...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChartErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.brandRed, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen.withAlpha(30),
                foregroundColor: AppColors.brandGreen,
                side: const BorderSide(color: AppColors.brandGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorPanel extends StatelessWidget {
  final String indicator;
  final List<Candle> candles;

  const _IndicatorPanel({required this.indicator, required this.candles});

  static List<FlSpot> _spots(String type, List<Candle> candles) {
    if (candles.isEmpty) return [];

    final reversedList = candles.reversed.toList();
    return List.generate(reversedList.length, (i) {
      final candle = reversedList[i];
      double y;
      if (type == 'RSI') {
        // RSI representation based on close-open movement
        final closeChange =
            candle.open > 0 ? (candle.close - candle.open) / candle.open : 0.0;
        y = 50.0 + (closeChange * 300).clamp(-40.0, 40.0);
      } else if (type == 'MACD') {
        // MACD representation
        final closeChange =
            candle.open > 0 ? (candle.close - candle.open) / candle.open : 0.0;
        y = closeChange * 12;
      } else {
        // Volume / other indicator representation
        y = (candle.high - candle.low) /
            (candle.open > 0 ? candle.open : 1) *
            20;
      }
      return FlSpot(i.toDouble(), y);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRsi = indicator == 'RSI';
    final spots = _spots(indicator, candles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$indicator Indicator',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            )),
        const SizedBox(height: 8),
        Expanded(
          child: spots.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 1))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    minY: isRsi ? 0 : null,
                    maxY: isRsi ? 100 : null,
                    extraLinesData: isRsi
                        ? ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: 70,
                                color: AppColors.brandRed.withAlpha(80),
                                strokeWidth: 0.8,
                                dashArray: [4, 4],
                              ),
                              HorizontalLine(
                                y: 30,
                                color: AppColors.brandGreen.withAlpha(80),
                                strokeWidth: 0.8,
                                dashArray: [4, 4],
                              ),
                            ],
                          )
                        : const ExtraLinesData(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.brandPurple,
                        barWidth: 1.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.brandPurple.withAlpha(15),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
