import 'package:ai_trading_copilot/core/remote/data/analysis/analysis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/coin_selector.dart';
import '../../providers/ai_analysis_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/charts_provider.dart';
import '../../providers/predictions_provider.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/selected_coin_provider.dart';
import '../../core/remote/data/predictions/models/predictions_models.dart';
import '../../core/widgets/coin_data_sections.dart';

const _coins = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'DOGE'];

String _coinIdFromSymbol(String s) {
  const map = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'BNB': 'binancecoin',
    'XRP': 'ripple',
    'DOGE': 'dogecoin',
    'ADA': 'cardano',
    'AVAX': 'avalanche-2',
  };
  return map[s.toUpperCase()] ?? s.toLowerCase();
}

// ConsumerStatefulWidget — keeps TextEditingController, stateless coin selection
class AiAnalysisScreen extends ConsumerStatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  void _openMobileChat(BuildContext context, String coin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: _AnalysisChatPanel(coin: coin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync aiAnalysisProvider with global coin (global search + navigation)
    final globalCoin = ref.watch(selectedCoinProvider);
    final currentCoin = ref.read(aiAnalysisProvider).selectedCoin;
    if (currentCoin != globalCoin) {
      Future.microtask(() {
        ref.read(aiAnalysisProvider).selectCoin(globalCoin);
        ref.read(chartsProvider).setCoin(globalCoin);
      });
    }
    ref.listen<String>(selectedCoinProvider, (_, coin) {
      ref.read(aiAnalysisProvider).selectCoin(coin);
      ref.read(chartsProvider).setCoin(coin);
    });

    final screenWidth = MediaQuery.sizeOf(context).width;
    final showChatPanel = screenWidth >= 900;
    final wide = screenWidth >= (showChatPanel ? 1400 : 860);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: showChatPanel
          ? null
          : Consumer(builder: (_, ref, __) {
              final coin =
                  ref.watch(aiAnalysisProvider.select((n) => n.selectedCoin));
              return FloatingActionButton.extended(
                onPressed: () => _openMobileChat(context, coin),
                backgroundColor: AppColors.brandGreen,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    const Text('Chat With AI',
                        style: TextStyle(fontSize: 13, color: Colors.black)),
                  ],
                ),
              );
            }),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main analysis panel ───────────────────────────────────────
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (_, ref, __) {
                      final coin = ref.watch(
                        aiAnalysisProvider.select((n) => n.selectedCoin),
                      );
                      final coinId = _coinIdFromSymbol(coin);
                      final accuracyAsync =
                          ref.watch(coinAccuracyProvider(coinId));
                      return _Header(
                        selectedCoin: coin,
                        coins: _coins,
                        accuracyAsync: accuracyAsync,
                        onCoinChanged: (c) {
                          ref.read(selectedCoinProvider.notifier).state = c;
                          ref.read(aiAnalysisProvider).selectCoin(c);
                          ref.read(chartsProvider).setCoin(c);
                          ref
                              .read(aiChatProvider.notifier)
                              .setCoin(_coinIdFromSymbol(c), c);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Consumer(
                    builder: (_, ref, __) {
                      final coin = ref.watch(
                        aiAnalysisProvider.select((n) => n.selectedCoin),
                      );
                      final tickerAsync = ref.watch(tickerProvider);
                      final currentPrice = tickerAsync.maybeWhen(
                        data: (live) => live['${coin}USDT']?.close,
                        orElse: () => null,
                      );
                      final coinId = _coinIdFromSymbol(coin);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MarketSummaryCard(coin: coin),
                          const SizedBox(height: 16),
                          Consumer(builder: (_, ref, __) {
                            final async = ref.watch(coinAiProvider(coinId));
                            Widget cards(Widget r, Widget s) => wide
                                ? Row(children: [
                                    Expanded(child: r),
                                    const SizedBox(width: 16),
                                    Expanded(child: s),
                                  ])
                                : Column(children: [
                                    r,
                                    const SizedBox(height: 16),
                                    s,
                                  ]);
                            return async.when(
                              loading: () => cards(
                                _SupportResistanceCard(
                                    currentPrice: currentPrice),
                                const _SentimentCard(),
                              ),
                              error: (_, __) => cards(
                                _SupportResistanceCard(
                                    currentPrice: currentPrice),
                                const _SentimentCard(),
                              ),
                              data: (a) {
                                final displayPrice = currentPrice ??
                                    a.currentPriceUsd ??
                                    a.analysis.currentPriceUsd;
                                return cards(
                                  _SupportResistanceCard(
                                      keyLevels: a.analysis.keyLevels,
                                      currentPrice: displayPrice),
                                  _SentimentCard(
                                      sentiment: a.analysis.sentimentBreakdown,
                                      trendDirection: a.analysis.trendDirection,
                                      confidenceScore: a.analysis.confidenceScore,
                                      keyInsights: a.analysis.keyInsights),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 16),
                          Consumer(builder: (_, ref, __) {
                            final async = ref.watch(coinAiProvider(coinId));
                            return async.when(
                              loading: () => const SizedBox(height: 120),
                              error: (_, __) => const _VolatilityCard(),
                              data: (a) => _VolatilityCard(
                                  volatilityAnalysis:
                                      a.analysis.volatilityAnalysis),
                            );
                          }),
                          const SizedBox(height: 16),
                          CoinFundingOiCard(coin: coin),
                          // const SizedBox(height: 16),
                          // CoinLiquidationsCard(coin: coin),
                          const SizedBox(height: 16),
                          Consumer(builder: (_, ref, __) {
                            final async = ref.watch(coinAiProvider(coinId));
                            return async.when(
                              loading: () => const SizedBox(height: 180),
                              error: (_, __) => const _KeyLevelsCard(),
                              data: (a) => _KeyLevelsCard(
                                  insights: a.analysis.keyInsights),
                            );
                          }),
                          const SizedBox(height: 16),
                          Consumer(builder: (_, ref, __) {
                            final async =
                                ref.watch(predictionHistoryProvider(coinId));
                            return async.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (records) => records.isEmpty
                                  ? const SizedBox.shrink()
                                  : _PredictionHistoryCard(records: records),
                            );
                          }),
                          const SizedBox(height: 16),
                          Consumer(builder: (_, ref, __) {
                            final async =
                                ref.watch(postMortemsProvider(coinId));
                            return async.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (mortems) => mortems.isEmpty
                                  ? const SizedBox.shrink()
                                  : _PostMortemsCard(mortems: mortems),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // ── AI chat sidebar (desktop only) ────────────────────────────
          if (showChatPanel)
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(left: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Consumer(builder: (_, ref, __) {
                final coin =
                    ref.watch(aiAnalysisProvider.select((n) => n.selectedCoin));
                return _AnalysisChatPanel(coin: coin);
              }),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String selectedCoin;
  final List<String> coins;
  final ValueChanged<String> onCoinChanged;
  final AsyncValue<CoinAccuracy> accuracyAsync;

  const _Header({
    required this.selectedCoin,
    required this.coins,
    required this.onCoinChanged,
    required this.accuracyAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Market Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Deep market intelligence · GPT-4',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  accuracyAsync.maybeWhen(
                    data: (acc) => acc.totalPredictions > 0
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _AccuracyBadge(accuracy: acc),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CoinSelector(selected: selectedCoin, onChanged: onCoinChanged),
      ],
    );
  }
}

class _AccuracyBadge extends StatelessWidget {
  final CoinAccuracy accuracy;
  const _AccuracyBadge({required this.accuracy});

  Color get _color {
    if (accuracy.accuracy >= 70) return AppColors.brandGreen;
    if (accuracy.accuracy >= 55) return AppColors.brandAmber;
    return AppColors.brandRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes_rounded, size: 10, color: _color),
          const SizedBox(width: 4),
          Text(
            'AI accuracy: ${accuracy.formattedAccuracy}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketSummaryCard extends StatelessWidget {
  final String coin;
  const _MarketSummaryCard({required this.coin});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.brandGreen.withAlpha(40),
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
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Market Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    Text('$coin/USDT · Updated 30s ago',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NeonBadge(
                  label: 'Bullish',
                  color: AppColors.brandGreen,
                  icon: Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: 16),
          // Use coin-specific AI analysis when available (resolve coinId slug)
          Consumer(builder: (_, ref, __) {
            final coinId = _coinIdFromSymbol(coin);
            final async = ref.watch(coinAiProvider(coinId));
            return async.when(
              loading: () => const Text('Loading AI analysis...',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xCCFFFFFF), height: 1.7)),
              error: (_, __) => const Text('Could not load AI analysis',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xCCFFFFFF), height: 1.7)),
              data: (a) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.analysis.summary,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xCCFFFFFF), height: 1.7)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 500;
                      final chips = [
                        _StatChip(
                            'Trend',
                            a.analysis.trendDirection,
                            a.analysis.trendDirection.toLowerCase() == 'bullish'
                                ? AppColors.brandGreen
                                : AppColors.brandRed,
                            isWide: isWide),
                        _StatChip(
                            'Confidence',
                            '${a.analysis.confidenceScore}%',
                            AppColors.brandAmber,
                            isWide: isWide),
                        _StatChip(
                            'Volatility',
                            a.analysis.volatilityAnalysis, // ← full text
                            AppColors.brandBlue,
                            isWide: isWide),
                      ];
                      return isWide
                          ? Row(
                              children: chips
                                  .map((c) => Expanded(
                                      child: c)) // ← equal width, stretches
                                  .expand((w) => [w, const SizedBox(width: 8)])
                                  .toList()
                                ..removeLast(),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: chips,
                            );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isWide;
  const _StatChip(this.label, this.value, this.color, {this.isWide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null, // ← fills Expanded on web
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportResistanceCard extends StatelessWidget {
  final KeyLevels? keyLevels;
  final double? currentPrice;
  const _SupportResistanceCard({this.keyLevels, this.currentPrice});

  @override
  Widget build(BuildContext context) {
    final levels = keyLevels;
    final hasResistance = levels != null && levels.resistance.isNotEmpty;
    final hasSupport = levels != null && levels.support.isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Support / Resistance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 16),
          if (hasResistance) ...[
            ...levels.resistance
                .map((r) => _Level(r.label, '\$${r.price.toStringAsFixed(2)}',
                    AppColors.brandRed, 0.6))
                .toList(),
          ] else ...[
            _Level('R3', '\$102,400', AppColors.brandRed, 0.9),
            _Level('R2', '\$100,000', AppColors.brandRed, 0.75),
            _Level('R1', '\$98,400', AppColors.brandRed, 0.6),
          ],
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandAmber.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.brandAmber.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Text('CURRENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandAmber,
                      letterSpacing: 0.5,
                    )),
                const Spacer(),
                _SupportPriceText(currentPrice: currentPrice),
              ],
            ),
          ),
          if (hasSupport) ...[
            ...levels.support
                .map((s) => _Level(s.label, '\$${s.price.toStringAsFixed(2)}',
                    AppColors.brandGreen, 0.55))
                .toList(),
          ] else ...[
            _Level('S1', '\$95,800', AppColors.brandGreen, 0.55),
            _Level('S2', '\$93,200', AppColors.brandGreen, 0.35),
            _Level('S3', '\$89,400', AppColors.brandGreen, 0.2),
          ],
        ],
      ),
    );
  }
}

class _SupportPriceText extends StatefulWidget {
  final double? currentPrice;
  const _SupportPriceText({super.key, required this.currentPrice});

  @override
  State<_SupportPriceText> createState() => _SupportPriceTextState();
}

class _SupportPriceTextState extends State<_SupportPriceText> {
  Color _textColor = Colors.white;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _SupportPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cur = widget.currentPrice;
    final prev = oldWidget.currentPrice;

    if (cur != null && prev != null && cur != prev) {
      _timer?.cancel();
      setState(() {
        _textColor = cur > prev ? AppColors.brandGreen : AppColors.brandRed;
      });
      _timer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _textColor = Colors.white;
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

  @override
  Widget build(BuildContext context) {
    final cur = widget.currentPrice;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _textColor,
        fontFamily: 'JetBrainsMono',
      ),
      child: Text(
        cur != null
            ? cur >= 1000
                ? '\$${cur.toStringAsFixed(0)}'
                : '\$${cur.toStringAsFixed(2)}'
            : '--',
      ),
    );
  }
}

class _Level extends StatelessWidget {
  final String label, price;
  final Color color;
  final double strength;
  const _Level(this.label, this.price, this.color, this.strength);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: AppColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(color.withAlpha(100)),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(price,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
        ],
      ),
    );
  }
}

class _SentimentCard extends StatelessWidget {
  final SentimentBreakdown? sentiment;
  final String? trendDirection;
  final int? confidenceScore;
  final List<String>? keyInsights;

  const _SentimentCard({
    this.sentiment,
    this.trendDirection,
    this.confidenceScore,
    this.keyInsights,
  });

  Color get _verdictColor {
    final t = trendDirection?.toLowerCase() ?? '';
    if (t.contains('bull') || t == 'buy' || t == 'long') {
      return AppColors.brandGreen;
    } else if (t.contains('bear') || t == 'sell' || t == 'short') {
      return AppColors.brandRed;
    }
    return AppColors.brandAmber;
  }

  String get _verdictText {
    if (trendDirection == null) return '—';
    final trend = trendDirection!;
    final conf = confidenceScore != null ? ' — $confidenceScore% confidence.' : '.';
    final insight = keyInsights?.isNotEmpty == true ? ' ${keyInsights!.first}' : '';
    return '${_capitalize(trend)} trend$conf$insight';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final s = sentiment;
    final verdictColor = _verdictColor;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sentiment Breakdown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 16),
          if (s != null) ...[
            _SentimentBar('Bullish', s.bullish, AppColors.brandGreen),
            _SentimentBar('Neutral', s.neutral, AppColors.brandAmber),
            _SentimentBar('Bearish', s.bearish, AppColors.brandRed),
          ] else ...[
            _SentimentBar('Bullish', 74, AppColors.brandGreen),
            _SentimentBar('Neutral', 18, AppColors.brandAmber),
            _SentimentBar('Bearish', 8, AppColors.brandRed),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const Text('AI Verdict',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: verdictColor.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: verdictColor.withAlpha(25)),
            ),
            child: Text(
              _verdictText,
              style:
                  TextStyle(fontSize: 11, color: verdictColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  const _SentimentBar(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              Text('$percent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'JetBrainsMono',
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolatilityCard extends StatelessWidget {
  final String? volatilityAnalysis;
  const _VolatilityCard({this.volatilityAnalysis});

  @override
  Widget build(BuildContext context) {
    final metrics = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _VolMetric('ATR-14', '3.2%', AppColors.brandAmber),
        _VolMetric('IV Rank', '38%', AppColors.brandBlue),
        _VolMetric('BB Width', '4.1%', AppColors.brandPurple),
      ],
    );

    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 500;
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Volatility Analysis',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 8),
                          Text(
                            volatilityAnalysis ?? _fallback,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        _VolMetric('ATR-14', '3.2%', AppColors.brandAmber),
                        const SizedBox(height: 8),
                        _VolMetric('IV Rank', '38%', AppColors.brandBlue),
                        const SizedBox(height: 8),
                        _VolMetric('BB Width', '4.1%', AppColors.brandPurple),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Volatility Analysis',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      volatilityAnalysis ?? _fallback,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    metrics,
                  ],
                );
        },
      ),
    );
  }

  static const _fallback = 'Current volatility (ATR-14) is moderate at 3.2%. '
      'Historical comparison: lower than the August 2024 high of 8.4%, '
      'suggesting controlled price action.';
}

class _VolMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _VolMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _KeyLevelsCard extends StatelessWidget {
  final List<String>? insights;
  const _KeyLevelsCard({this.insights});

  @override
  Widget build(BuildContext context) {
    final items = insights ??
        [
          'Watch for break above \$98,400 — would signal continuation to \$100K',
          'Funding rates neutral — healthy conditions, not overleveraged',
          'ETF inflows positive for 3rd day — institutional accumulation',
          'Risk: rejection at \$98.4K could cause sharp drop to \$94K',
        ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Insights',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) {
            final colors = [
              AppColors.brandGreen,
              AppColors.brandBlue,
              AppColors.brandPurple,
              AppColors.brandAmber
            ];
            final icons = [
              Icons.trending_up_rounded,
              Icons.balance_rounded,
              Icons.account_balance_rounded,
              Icons.warning_amber_rounded
            ];
            final idx = e.key % colors.length;
            return _Insight(e.value, icons[idx], colors[idx]);
          }).toList(),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Insight(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ))),
        ],
      ),
    );
  }
}

// ── Prediction History Card ────────────────────────────────────────────────────

class _PredictionHistoryCard extends StatelessWidget {
  final List<PredictionRecord> records;
  const _PredictionHistoryCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final shown = records.take(5).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Past AI Predictions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
              const Spacer(),
              Text('${records.length} total',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ...shown.map((r) => _PredictionRow(record: r)),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final PredictionRecord record;
  const _PredictionRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isBull = record.isBullish;
    final directionColor = isBull ? AppColors.brandGreen : AppColors.brandRed;
    final statusColor = record.isCorrect
        ? AppColors.brandGreen
        : record.isPending
            ? AppColors.brandAmber
            : AppColors.brandRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isBull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: directionColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              record.direction.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: directionColor,
              ),
            ),
          ),
          if (record.targetPrice != null)
            Text(
              '\$${record.targetPrice!.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'JetBrainsMono'),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post Mortems Card ──────────────────────────────────────────────────────────

class _PostMortemsCard extends StatelessWidget {
  final List<PostMortem> mortems;
  const _PostMortemsCard({required this.mortems});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.brandAmber.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_fix_off_rounded,
                    size: 14, color: AppColors.brandAmber),
              ),
              const SizedBox(width: 10),
              const Text('Why Was AI Wrong?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          ...mortems.take(3).map((m) => _MortemItem(mortem: m)),
        ],
      ),
    );
  }
}

class _MortemItem extends StatelessWidget {
  final PostMortem mortem;
  const _MortemItem({required this.mortem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.brandAmber.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandAmber.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Predicted ${mortem.predictedDirection.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandAmber,
                ),
              ),
              const Text(' → ',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                mortem.actualOutcome.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandRed,
                ),
              ),
            ],
          ),
          if (mortem.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mortem.explanation,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted, height: 1.5),
            ),
          ],
          if (mortem.lessons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...mortem.lessons.map((l) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 11, color: AppColors.brandGreen),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(l,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.brandGreen,
                              height: 1.4)),
                    ),
                  ],
                )),
          ],
        ],
      ),
    );
  }
}

// ── Analysis screen embedded chat panel ───────────────────────────────────────

class _AnalysisChatPanel extends ConsumerStatefulWidget {
  final String coin;
  const _AnalysisChatPanel({required this.coin});

  @override
  ConsumerState<_AnalysisChatPanel> createState() => _AnalysisChatPanelState();
}

class _AnalysisChatPanelState extends ConsumerState<_AnalysisChatPanel> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<String> _prompts(String coin) => [
        'What is the $coin market structure right now?',
        'What are key support/resistance levels for $coin?',
        'Is this a good entry for $coin?',
        'Explain the $coin funding rate',
      ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiChatProvider.notifier).send(text);
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider.select((s) => s.messages));
    final isStreaming = ref.watch(aiChatProvider.select((s) => s.isStreaming));

    // Hide suggestions once user has sent at least one message
    final hasUserMessage = messages.any((m) => m.isUser);

    // Auto-scroll on new tokens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 15, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ask AI · ${widget.coin}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.coin,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suggestions — only shown before first user message
        if (!hasUserMessage)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _SuggestedPrompts(
              prompts: _prompts(widget.coin),
              onTap: _send,
            ),
          ),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChatBubble(
                          text: msg.text,
                          isUser: msg.isUser,
                          isStreaming: msg.isStreaming),
                    );
                  },
                ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !isStreaming,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  onSubmitted: isStreaming ? null : _send,
                  decoration: InputDecoration(
                    hintText: isStreaming
                        ? 'AI is responding…'
                        : 'Ask about ${widget.coin}...',
                    hintStyle: const TextStyle(
                        color: AppColors.textDisabled, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isStreaming ? null : () => _send(_ctrl.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isStreaming ? null : AppColors.gradientGreen,
                    color: isStreaming ? AppColors.bgCard : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: isStreaming
                      ? const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.brandGreen),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          size: 15, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestedPrompts extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onTap;
  const _SuggestedPrompts({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Suggested',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: prompts
              .map((p) => GestureDetector(
                    onTap: () => onTap(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          )),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;
  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brandGreen.withAlpha(20) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUser
                ? AppColors.brandGreen.withAlpha(40)
                : AppColors.borderSubtle,
          ),
        ),
        child: isStreaming && text.isEmpty
            ? const _MiniTypingDots()
            : Text(text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xCCFFFFFF),
                  height: 1.5,
                )),
      ),
    );
  }
}

class _MiniTypingDots extends StatefulWidget {
  const _MiniTypingDots();

  @override
  State<_MiniTypingDots> createState() => _MiniTypingDotsState();
}

class _MiniTypingDotsState extends State<_MiniTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withAlpha(
                (80 + 120 * ((_c.value + i * 0.3) % 1.0)).toInt(),
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
