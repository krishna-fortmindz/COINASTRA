import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import '../../providers/coin_socket_providers.dart';
import '../remote/web_socket_baseclass.dart';

// ── Funding Rate + OI History Card ───────────────────────────────────────────

class CoinFundingOiCard extends ConsumerWidget {
  final String coin;
  const CoinFundingOiCard({super.key, required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = '${coin.toUpperCase()}USDT';
    final async = ref.watch(coinHistoryProvider(sym));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waterfall_chart_rounded,
                  size: 14, color: AppColors.brandPurple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Funding Rate & OI History',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withAlpha(18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('24H',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPurple)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandPurple),
                    ),
                    SizedBox(height: 8),
                    Text('Fetching data...',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            error: (_, __) => const Center(
              child: Text('Could not load history',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
            data: (data) => _FundingOiContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _FundingOiContent extends StatelessWidget {
  final CoinHistoryData data;
  const _FundingOiContent({required this.data});

  Color get _fundingColor {
    if (!data.fundingPositive) return AppColors.brandGreen;
    if (data.fundingRate > 0.0004) return AppColors.brandRed;
    if (data.fundingRate > 0.0002) return AppColors.brandAmber;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final color = _fundingColor;
    final candles = data.oiHistory;
    final hasOi = candles.isNotEmpty;
    final latestOiUsd = hasOi ? candles.last.openInterestValue : 0.0;
    final trendUp = candles.length > 1 &&
        candles.last.openInterestValue >= candles.first.openInterestValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Funding Rate',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(data.formattedFunding,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontFamily: 'JetBrainsMono',
                          )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(data.fundingLevel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.fundingPositive
                        ? 'Longs paying shorts — bullish overcrowding'
                        : 'Shorts paying longs — bearish dominance',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            if (hasOi) ...[
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatOi(latestOiUsd),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: trendUp
                          ? AppColors.brandGreen
                          : AppColors.brandAmber,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 11,
                        color: trendUp
                            ? AppColors.brandGreen
                            : AppColors.brandAmber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'OI',
                        style: TextStyle(
                          fontSize: 10,
                          color: trendUp
                              ? AppColors.brandGreen
                              : AppColors.brandAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
        if (hasOi) ...[
          const SizedBox(height: 14),
          const Text('Open Interest (24h)',
              style:
                  TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          _OiBarChart(candles: candles, trendUp: trendUp),
        ],
      ],
    );
  }

  String _formatOi(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _OiBarChart extends StatelessWidget {
  final List<OiCandle> candles;
  final bool trendUp;
  const _OiBarChart({required this.candles, required this.trendUp});

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();
    final values = candles.map((c) => c.openInterestValue).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    const maxH = 44.0;
    const minH = 4.0;
    final barColor =
        trendUp ? AppColors.brandGreen : AppColors.brandAmber;

    return SizedBox(
      height: maxH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: candles.asMap().entries.map((e) {
          final isLast = e.key == candles.length - 1;
          final norm = range > 0
              ? (e.value.openInterestValue - minV) / range
              : 0.5;
          final barH =
              (minH + norm * (maxH - minH)).clamp(minH, maxH);
          return Expanded(
            child: Container(
              height: barH,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: barColor.withAlpha(isLast ? 200 : 90),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Liquidations Card ─────────────────────────────────────────────────────────

class CoinLiquidationsCard extends ConsumerWidget {
  final String coin;
  const CoinLiquidationsCard({super.key, required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = '${coin.toUpperCase()}USDT';
    final async = ref.watch(coinLiquidationsProvider(sym));

    return GlassCard(
      borderColor: AppColors.brandRed.withAlpha(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 14, color: AppColors.brandRed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Liquidations (Last 60 min)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              async.maybeWhen(
                data: (d) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed.withAlpha(18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${d.count} events',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandRed)),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandRed),
                    ),
                    SizedBox(height: 8),
                    Text('Loading liquidations...',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            error: (_, __) => const Center(
              child: Text('Could not load liquidations',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
            data: (data) => _LiquidationsContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _LiquidationsContent extends StatelessWidget {
  final CoinLiquidationData data;
  const _LiquidationsContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brandAmber.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.brandAmber.withAlpha(30)),
        ),
        child: const Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 13, color: AppColors.brandAmber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Server is warming up. Liquidation data will appear within a few minutes of market activity.',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.brandAmber,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    final longsStr = data.formatUsd(data.longsRektUsd);
    final shortsStr = data.formatUsd(data.shortsRektUsd);
    final shown = data.recentEvents.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _LiqTile(
                label: 'Longs Rekt',
                value: longsStr,
                color: AppColors.brandRed,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiqTile(
                label: 'Shorts Rekt',
                value: shortsStr,
                color: AppColors.brandGreen,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Recent Events',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ...shown.map((e) => _LiqEventRow(event: e)),
        ],
      ],
    );
  }
}

class _LiqTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _LiqTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
        ],
      ),
    );
  }
}

class _LiqEventRow extends StatelessWidget {
  final LiquidationEvent event;
  const _LiqEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isLong = event.isLongLiq;
    final color = isLong ? AppColors.brandRed : AppColors.brandGreen;
    final label = isLong ? 'LONG' : 'SHORT';
    final mins = DateTime.now().difference(event.time).inMinutes;
    final timeStr = mins < 1 ? 'just now' : '${mins}m ago';
    final baseSymbol = event.symbol.replaceAll('USDT', '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3)),
            ),
          ),
          const SizedBox(width: 8),
          Text(event.formattedPrice,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'JetBrainsMono',
              )),
          const SizedBox(width: 6),
          Text('${event.quantity.toStringAsFixed(2)} $baseSymbol',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
          const Spacer(),
          Text(timeStr,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textDisabled)),
        ],
      ),
    );
  }
}
