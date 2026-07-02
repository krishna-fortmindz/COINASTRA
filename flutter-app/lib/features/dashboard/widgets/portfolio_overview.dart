import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/web_socket_baseclass.dart';
import '../../../providers/dashboard_provider.dart';

class PortfolioOverview extends ConsumerWidget {
  const PortfolioOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(tickerProvider);
    final live = liveAsync.valueOrNull ?? {};

    final symbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT'];
    final tickers = symbols
        .map((s) => live[s])
        .whereType<TickerUpdate>()
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Market Stats',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('24h High · Low · Volume',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tickers.isNotEmpty
                      ? AppColors.brandGreen
                      : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tickers.isNotEmpty ? 'Live' : 'Waiting…',
                style: TextStyle(
                  fontSize: 10,
                  color: tickers.isNotEmpty
                      ? AppColors.brandGreen
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tickers.isEmpty)
            const _WaitingState()
          else
            ...tickers.map((t) => _TickerRow(ticker: t)),
        ],
      ),
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(width: 36, height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(4))),
              const Spacer(),
              Container(width: 60, height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickerRow extends StatelessWidget {
  final TickerUpdate ticker;
  const _TickerRow({required this.ticker});

  String _fmt(double v) {
    if (v >= 1000) return '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsFixed(4)}';
  }

  String _fmtVol(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final change = ticker.priceChangePercent;
    final isPositive = change >= 0;
    final changeColor = isPositive ? AppColors.brandGreen : AppColors.brandRed;
    final symbol = ticker.symbol.replaceAll('USDT', '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(symbol,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('H ${_fmt(ticker.high)}',
                        style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Text('L ${_fmt(ticker.low)}',
                        style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ticker.high > ticker.low
                        ? (ticker.close - ticker.low) / (ticker.high - ticker.low)
                        : 0.5,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation(changeColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: changeColor,
                      fontFamily: 'JetBrainsMono')),
              Text('Vol \$${_fmtVol(ticker.quoteVolume)}',
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}