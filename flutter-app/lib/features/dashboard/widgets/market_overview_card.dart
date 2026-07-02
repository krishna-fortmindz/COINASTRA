import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../../providers/ai_analysis_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/remote/web_socket_baseclass.dart';

Color _coinColor(String symbol) {
  const map = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'BNB': Color(0xFFF3BA2F),
    'XRP': Color(0xFF0085C3),
    'DOGE': Color(0xFFC2A633),
    'ADA': Color(0xFF0033AD),
    'AVAX': Color(0xFFE84142),
  };
  return map[symbol] ?? AppColors.brandGreen;
}

class MarketOverviewCards extends ConsumerStatefulWidget {
  const MarketOverviewCards({super.key});

  @override
  ConsumerState<MarketOverviewCards> createState() =>
      _MarketOverviewCardsState();
}

class _MarketOverviewCardsState extends ConsumerState<MarketOverviewCards> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(marketCoinsProvider);
    return async.when(
      loading: _buildShimmer,
      error: (e, _) => _buildError(),
      data: _buildGrid,
    );
  }

  Widget _buildGrid(List<MarketCoin> coins) {
    final liveAsync = ref.watch(tickerProvider);
    final live = liveAsync.valueOrNull ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 768;

        final crossCount = width >= 1400
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 2
                    : 2;

        // Mobile: fixed pixel height per card so fl_chart always has room.
        // Desktop: use aspect ratio as before.
        final aspectRatio = isMobile
            ? crossCount == 2
                ? 0.85
                : 0.68
            : width >= 1200
                ? 2.8
                : 2.2;

        final collapsedCount = crossCount * 2;
        final visibleCount = _expanded ? coins.length : collapsedCount;
        final visible = coins.take(visibleCount).toList();
        final hasMore = coins.length > collapsedCount;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: aspectRatio,
                  children: visible.map((coin) {
                    final ticker = live['${coin.symbol}USDT'];
                    return _CoinCard(
                      coin: coin,
                      liveTicker: ticker,
                      compact: isMobile,
                      onTap: () {
                        ref.read(aiAnalysisProvider).selectCoin(coin.symbol);
                        context.go('/analysis');
                      },
                    );
                  }).toList(),
                ),
                if (hasMore) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _expanded
                                  ? 'Show Less'
                                  : 'See More (${coins.length - visibleCount} more)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.brandGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildShimmer() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: List.generate(
        6,
        (_) => Shimmer.fromColors(
          baseColor: AppColors.bgCard,
          highlightColor: AppColors.bgTertiary,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Could not load market data',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(marketCoinsProvider),
            child: const Text('Retry',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CoinCard extends StatefulWidget {
  final MarketCoin coin;
  final TickerUpdate? liveTicker;
  final bool compact;
  final VoidCallback onTap;

  const _CoinCard({
    super.key,
    required this.coin,
    this.liveTicker,
    this.compact = false,
    required this.onTap,
  });

  @override
  State<_CoinCard> createState() => _CoinCardState();
}

class _CoinCardState extends State<_CoinCard> {
  Color _priceColor = Colors.white;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _CoinCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentPrice = widget.liveTicker?.close ?? widget.coin.currentPrice;
    final oldPrice = oldWidget.liveTicker?.close ?? oldWidget.coin.currentPrice;

    if (currentPrice != oldPrice) {
      _timer?.cancel();
      setState(() {
        _priceColor = currentPrice > oldPrice ? AppColors.brandGreen : AppColors.brandRed;
      });
      _timer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _priceColor = Colors.white;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _priceText {
    final p = widget.liveTicker?.close ?? widget.coin.currentPrice;
    if (p >= 1000) return '\$${p.toStringAsFixed(2)}';
    if (p >= 1) return '\$${p.toStringAsFixed(2)}';
    return '\$${p.toStringAsFixed(4)}';
  }

  String get _changeText {
    final c = widget.liveTicker?.priceChangePercent ?? widget.coin.priceChange24h;
    return '${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)}%';
  }

  bool get _isPositive =>
      (widget.liveTicker?.priceChangePercent ?? widget.coin.priceChange24h) >= 0;

  @override
  Widget build(BuildContext context) =>
      widget.compact ? _buildCompact() : _buildWide();

  // ── Mobile: vertical card ────────────────────────────────────
  Widget _buildCompact() {
    final color = _coinColor(widget.coin.symbol);
    final changeColor = _isPositive ? AppColors.brandGreen : AppColors.brandRed;

    return GlassCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Top row: icon + change badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withAlpha(25), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    widget.coin.symbol[0],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _changeText,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrainsMono',
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Symbol + price ──
          Text(
            widget.coin.symbol,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _priceColor,
              fontFamily: 'JetBrainsMono',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Text(_priceText),
          ),

          // ── Sparkline: Expanded fills remaining card height ──
          if (widget.coin.sparkline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.coin.sparkline
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: changeColor,
                      barWidth: 1.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: changeColor.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tablet / Desktop: horizontal card ───────────────────────
  Widget _buildWide() {
    final color = _coinColor(widget.coin.symbol);
    final changeColor = _isPositive ? AppColors.brandGreen : AppColors.brandRed;

    return GlassCard(
      onTap: widget.onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withAlpha(25), shape: BoxShape.circle),
            child: Center(
              child: Text(
                widget.coin.symbol[0],
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.coin.symbol,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  widget.coin.name,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _priceColor,
                    fontFamily: 'JetBrainsMono'),
                child: Text(_priceText),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _changeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrainsMono',
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          if (widget.coin.sparkline.isNotEmpty)
            SizedBox(
              width: 60,
              height: 30,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.coin.sparkline
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: changeColor,
                      barWidth: 1.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: changeColor.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
