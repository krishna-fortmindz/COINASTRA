import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/remote/web_socket_baseclass.dart';

class WhaleAlerts extends ConsumerWidget {
  const WhaleAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveWhaleProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    final liveAlerts = liveAsync.value ?? const <LiveWhaleAlert>[];
    final restAlerts = summaryAsync.valueOrNull?.whaleAlerts ?? _fallback;

    // Build unified raw data list for "View All" sheet
    final allAlertData = <_AlertData>[];
    final cardWidgets = <Widget>[];

    for (final a in liveAlerts) {
      final data = _AlertData(
        symbol: a.symbol, amount: a.amount, amountUsd: a.amountUsd,
        from: a.from, to: a.to, timestamp: a.timestamp,
        toExchange: a.toExchange, formattedAmount: a.formattedAmount,
        emoji: a.emoji, isLive: true,
      );
      allAlertData.add(data);
      if (cardWidgets.length < 5) {
        cardWidgets.add(_AlertRow(
          key: ValueKey('live_${a.symbol}_${a.amount}_${a.timestamp.millisecondsSinceEpoch}'),
          symbol: a.symbol, amount: a.amount, amountUsd: a.amountUsd,
          from: a.from, to: a.to, timestamp: a.timestamp,
          toExchange: a.toExchange, formattedAmount: a.formattedAmount,
          emoji: a.emoji, isLive: true,
        ));
      }
    }

    for (final a in restAlerts) {
      final isDuplicate = liveAlerts.any((la) =>
          la.symbol == a.symbol &&
          la.timestamp.difference(a.timestamp).inSeconds.abs() < 5);
      if (!isDuplicate) {
        allAlertData.add(_AlertData(
          symbol: a.symbol, amount: a.amount, amountUsd: a.amountUsd,
          from: a.from, to: a.to, timestamp: a.timestamp,
          toExchange: a.toExchange, formattedAmount: a.formattedAmount,
          emoji: a.emoji, isLive: false,
        ));
        if (cardWidgets.length < 5) {
          cardWidgets.add(_AlertRow(
            key: ValueKey('rest_${a.symbol}_${a.amount}_${a.timestamp.millisecondsSinceEpoch}'),
            symbol: a.symbol, amount: a.amount, amountUsd: a.amountUsd,
            from: a.from, to: a.to, timestamp: a.timestamp,
            toExchange: a.toExchange, formattedAmount: a.formattedAmount,
            emoji: a.emoji, isLive: false,
          ));
        }
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Whale Alerts',
                  subtitle: 'Large transactions · Real-time',
                ),
              ),
              if (liveAlerts.isNotEmpty) ...[
                const NeonBadge(label: 'LIVE', color: AppColors.brandGreen),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: () => _showAllAlerts(context, allAlertData),
                child: const Text('View All', style: TextStyle(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...cardWidgets,
        ],
      ),
    );
  }

  void _showAllAlerts(BuildContext context, List<_AlertData> allAlerts) {
    final queryNotifier = ValueNotifier<String>('');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (innerCtx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('All Whale Alerts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    onChanged: (v) => queryNotifier.value = v,
                    decoration: const InputDecoration(
                      hintText: 'Search by coin...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: queryNotifier,
                  builder: (_, query, __) {
                    final filtered = query.isEmpty
                        ? allAlerts
                        : allAlerts
                            .where((a) => a.symbol.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No results',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final a = filtered[i];
                        return _AlertRow(
                          symbol: a.symbol, amount: a.amount,
                          amountUsd: a.amountUsd, from: a.from, to: a.to,
                          timestamp: a.timestamp, toExchange: a.toExchange,
                          formattedAmount: a.formattedAmount,
                          emoji: a.emoji, isLive: a.isLive,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _now = DateTime.now();
  static final _fallback = [
    WhaleAlert(symbol: 'BTC', amount: 2840, amountUsd: 276800000,
      from: 'Unknown', to: 'Binance',
      timestamp: _now.subtract(const Duration(minutes: 4))),
    WhaleAlert(symbol: 'ETH', amount: 14200, amountUsd: 54600000,
      from: 'Coinbase', to: 'Unknown',
      timestamp: _now.subtract(const Duration(minutes: 12))),
    WhaleAlert(symbol: 'USDT', amount: 85000000, amountUsd: 85000000,
      from: 'Binance', to: 'Unknown',
      timestamp: _now.subtract(const Duration(minutes: 28))),
    WhaleAlert(symbol: 'BTC', amount: 1200, amountUsd: 117000000,
      from: 'Kraken', to: 'Unknown',
      timestamp: _now.subtract(const Duration(minutes: 45))),
    WhaleAlert(symbol: 'ETH', amount: 9500, amountUsd: 36500000,
      from: 'Unknown', to: 'OKX',
      timestamp: _now.subtract(const Duration(hours: 1))),
  ];
}

class _AlertData {
  final String symbol;
  final double amount;
  final double amountUsd;
  final String from;
  final String to;
  final DateTime timestamp;
  final bool toExchange;
  final String formattedAmount;
  final String emoji;
  final bool isLive;

  const _AlertData({
    required this.symbol,
    required this.amount,
    required this.amountUsd,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.toExchange,
    required this.formattedAmount,
    required this.emoji,
    required this.isLive,
  });
}

class _AlertRow extends StatelessWidget {
  final String symbol;
  final double amount;
  final double amountUsd;
  final String from;
  final String to;
  final DateTime timestamp;
  final bool toExchange;
  final String formattedAmount;
  final String emoji;
  final bool isLive;

  const _AlertRow({
    super.key,
    required this.symbol,
    required this.amount,
    required this.amountUsd,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.toExchange,
    required this.formattedAmount,
    required this.emoji,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$formattedAmount $symbol',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'JetBrainsMono',
                  )),
                Text('$from → $to',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeago.format(timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.textDisabled)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: (toExchange ? AppColors.brandRed : AppColors.brandAmber).withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  toExchange ? 'To Exchange' : 'From Exchange',
                  style: TextStyle(
                    fontSize: 8, fontWeight: FontWeight.w600,
                    color: toExchange ? AppColors.brandRed : AppColors.brandAmber,
                  )),
              ),
            ],
          ),
        ],
      ),
    );

    if (isLive) {
      row = row.animate()
          .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad)
          .fadeIn(duration: 400.ms);
    }

    return row;
  }
}