import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/market_memory_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/selected_coin_provider.dart';

class MarketMemoryScreen extends ConsumerStatefulWidget {
  const MarketMemoryScreen({super.key});

  @override
  ConsumerState<MarketMemoryScreen> createState() => _MarketMemoryScreenState();
}

class _MarketMemoryScreenState extends ConsumerState<MarketMemoryScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectCoin(String symbol) {
    final upper = symbol.trim().toUpperCase();
    if (upper.isNotEmpty) {
      ref.read(memorySymbolProvider.notifier).state = upper;
    }
    setState(() {
      _searching = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sync with global search selection
    final globalCoin = ref.watch(selectedCoinProvider);
    final currentMemoryCoin = ref.read(memorySymbolProvider);
    if (currentMemoryCoin != globalCoin) {
      Future.microtask(
          () => ref.read(memorySymbolProvider.notifier).state = globalCoin);
    }

    final symbol = ref.watch(memorySymbolProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
                symbol: symbol,
                onSearch: () => setState(() => _searching = !_searching)),
            if (_searching) ...[
              const SizedBox(height: 12),
              _buildSearchField(symbol),
            ],
            const SizedBox(height: 20),
            _MacroContextCard(symbol: symbol),
            const SizedBox(height: 20),
            _MarketCycleCard(symbol: symbol),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Similar Historical Events',
              subtitle: 'Ranked by structural similarity',
            ),
            const SizedBox(height: 12),
            _SimilarEventsSection(symbol: symbol),
            const SizedBox(height: 20),
            _PatternsSection(symbol: symbol),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(String currentSymbol) {
    const quickCoins = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'ADA', 'AVAX', 'DOGE'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPurple.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'JetBrainsMono'),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Search any coin...',
                    hintStyle:
                        TextStyle(color: AppColors.textDisabled, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                  onSubmitted: _selectCoin,
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                  }),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_query.length >= 2)
          _MemoryCoinSearchResults(query: _query, onTap: _selectCoin)
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickCoins.map((coin) {
              final isSelected = coin == currentSymbol;
              return GestureDetector(
                onTap: () => _selectCoin(coin),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPurple.withAlpha(40)
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandPurple.withAlpha(80)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Text(coin,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.brandPurple
                            : AppColors.textMuted,
                      )),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// API-powered coin search results for Market Memory
// ─────────────────────────────────────────────────────────────

class _MemoryCoinSearchResults extends ConsumerWidget {
  final String query;
  final void Function(String symbol) onTap;
  const _MemoryCoinSearchResults({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coinSearchProvider(query));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: AppColors.brandPurple, strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Could not load coins',
            style: TextStyle(fontSize: 12, color: AppColors.brandRed)),
      ),
      data: (coins) {
        if (coins.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No coins found',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: coins.take(8).map((coin) {
              final changeColor =
                  coin.positive ? AppColors.brandGreen : AppColors.brandRed;
              return GestureDetector(
                onTap: () => onTap(coin.symbol),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            coin.symbol.isNotEmpty ? coin.symbol[0] : '?',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPurple),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(coin.symbol,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text(coin.name,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(coin.formattedChange,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: changeColor,
                              fontFamily: 'JetBrainsMono')),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header with coin selector
// ─────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String symbol;
  final VoidCallback onSearch;
  const _Header({required this.symbol, required this.onSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPurple.withAlpha(40)),
          ),
          child: const Icon(
            Icons.history_edu_rounded,
            color: AppColors.brandPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Memory Engine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'RAG-powered historical pattern matching · $symbol/USDT',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.brandPurple.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded,
                    size: 14, color: AppColors.brandPurple),
                const SizedBox(width: 4),
                Text(symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPurple,
                      fontFamily: 'JetBrainsMono',
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Macro Context Card
// ─────────────────────────────────────────────────────────────

class _MacroContextCard extends ConsumerWidget {
  final String symbol;
  const _MacroContextCard({required this.symbol});

  Color _fearGreedColor(int value) {
    if (value < 25) return AppColors.brandRed;
    if (value < 45) return AppColors.brandAmber;
    if (value < 55) return const Color(0xFFEAB308); // yellow
    return AppColors.brandGreen;
  }

  String _fearGreedLabel(int value, String? labelFromApi) {
    if (labelFromApi != null && labelFromApi.isNotEmpty) return labelFromApi;
    if (value < 25) return 'Extreme Fear';
    if (value < 45) return 'Fear';
    if (value < 55) return 'Neutral';
    if (value < 75) return 'Greed';
    return 'Extreme Greed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMacro = ref.watch(macroContextProvider);

    return asyncMacro.when(
      loading: () => GlassCard(
        borderColor: AppColors.brandGreen.withAlpha(40),
        child: const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandPurple,
            ),
          ),
        ),
      ),
      error: (_, __) => GlassCard(
        borderColor: AppColors.brandRed.withAlpha(40),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.brandAmber, size: 16),
            SizedBox(width: 8),
            Text(
              'Unable to load macro context',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      data: (macro) {
        if (macro == null) {
          return GlassCard(
            borderColor: AppColors.borderSubtle,
            child: const Center(
              child: Text(
                'No macro context available',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          );
        }

        final fgValue = macro.fearGreedCurrent;
        final fgColor =
            fgValue != null ? _fearGreedColor(fgValue) : AppColors.textMuted;
        final fgLabel = fgValue != null
            ? _fearGreedLabel(fgValue, macro.fearGreedLabel)
            : macro.fearGreedLabel ?? 'N/A';

        return GlassCard(
          borderColor: AppColors.brandGreen.withAlpha(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Market State',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (macro.btcDominance != null)
                    _StateChip(
                      'BTC Dom ${macro.btcDominance!.toStringAsFixed(1)}%',
                      AppColors.brandBlue,
                    ),
                  if (fgValue != null)
                    _StateChip(
                      'Fear & Greed $fgValue · $fgLabel',
                      fgColor,
                    ),
                  ...macro.keySignals.map(
                    (s) => _StateChip(s, AppColors.brandPurple),
                  ),
                ],
              ),
              if (macro.aiSummary != null && macro.aiSummary!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.brandPurple.withAlpha(25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology_rounded,
                          color: AppColors.brandPurple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          macro.aiSummary!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Market Cycle Card
// ─────────────────────────────────────────────────────────────

class _MarketCycleCard extends ConsumerWidget {
  final String symbol;
  const _MarketCycleCard({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCycle = ref.watch(marketCyclesProvider(symbol));

    return asyncCycle.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cycle) {
        if (cycle == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Market Cycle',
              subtitle: 'Bitcoin cycle analysis',
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderColor: AppColors.brandBlue.withAlpha(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase chip
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StateChip(cycle.currentPhase, AppColors.brandBlue),
                    ],
                  ),
                  // Days since cycle start
                  if (cycle.daysSinceStart != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${cycle.daysSinceStart}d since cycle start',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                  // Description
                  if (cycle.description != null &&
                      cycle.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      cycle.description!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.5),
                    ),
                  ],
                  // Historical cycles list
                  if (cycle.historicalCycles.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'HISTORICAL CYCLES',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cycle.historicalCycles.map(
                      (hc) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bgTertiary,
                                borderRadius: BorderRadius.circular(5),
                                border:
                                    Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                hc.period,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hc.phase,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white70),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  hc.positive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 12,
                                  color: hc.positive
                                      ? AppColors.brandGreen
                                      : AppColors.brandRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hc.outcome,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: hc.positive
                                        ? AppColors.brandGreen
                                        : AppColors.brandRed,
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Similar Events Section
// ─────────────────────────────────────────────────────────────

class _SimilarEventsSection extends ConsumerWidget {
  final String symbol;
  const _SimilarEventsSection({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(similarEventsProvider(symbol));

    return asyncEvents.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandPurple,
          ),
        ),
      ),
      error: (e, __) => GlassCard(
        borderColor: AppColors.brandRed.withAlpha(40),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.brandRed, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load similar events: ${e.toString().split('\n').first}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const GlassCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No similar events found',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
          );
        }
        return Column(
          children: events
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SimilarEventCard(event: e),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Technical Patterns Section
// ─────────────────────────────────────────────────────────────

class _PatternsSection extends ConsumerWidget {
  final String symbol;
  const _PatternsSection({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatterns = ref.watch(marketPatternsProvider(symbol));

    return asyncPatterns.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (patterns) {
        if (patterns.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Technical Patterns',
              subtitle: 'Detected by AI analysis engine',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: patterns.map((p) {
                final color = p.direction?.toLowerCase() == 'bullish'
                    ? AppColors.brandGreen
                    : p.direction?.toLowerCase() == 'bearish'
                        ? AppColors.brandRed
                        : AppColors.brandPurple;
                return _StateChip(
                  p.confidence != null
                      ? '${p.patternType} (${p.confidence!.toStringAsFixed(0)}%)'
                      : p.patternType,
                  color,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Similar Event Card (mirrors old _PatternCard visuals)
// ─────────────────────────────────────────────────────────────

class _SimilarEventCard extends StatelessWidget {
  final SimilarEvent event;
  const _SimilarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final similarityColor = event.similarity > 75
        ? AppColors.brandGreen
        : event.similarity > 55
            ? AppColors.brandAmber
            : AppColors.brandRed;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  event.date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${event.similarity}% match',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: similarityColor,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: event.similarity / 100,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation(similarityColor),
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
          if (event.keyFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: event.keyFactors
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                event.positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color:
                    event.positive ? AppColors.brandGreen : AppColors.brandRed,
              ),
              const SizedBox(width: 6),
              const Text(
                'Historical Outcome: ',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                event.outcome,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: event.positive
                      ? AppColors.brandGreen
                      : AppColors.brandRed,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared chip widget
// ─────────────────────────────────────────────────────────────

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StateChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
