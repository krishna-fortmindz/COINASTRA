import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../../providers/dashboard_provider.dart';

class FundingRatePanel extends ConsumerWidget {
  const FundingRatePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveFundingAsync = ref.watch(liveFundingProvider);
    final restFundingAsync = ref.watch(fundingRatesProvider);

    // Resolve full list for "View All" sheet (REST data or fallback)
    final fullRates = restFundingAsync.valueOrNull?.isNotEmpty == true
        ? restFundingAsync.valueOrNull!
        : _fallback;

    // If live socket data is available, display it
    if (liveFundingAsync.hasValue && liveFundingAsync.value!.isNotEmpty) {
      final rates = liveFundingAsync.value!;
      // Convert LiveFundingRate to FundingRate for _buildCard
      final fundingRates = rates.map((r) => FundingRate(
        symbol: r.symbol,
        rate: r.rate,
      )).toList();
      return _buildCard(context, rates: fundingRates, isLive: true, allRates: fullRates);
    }

    // Fallback to REST
    return restFundingAsync.when(
      loading: _buildShimmer,
      error: (_, __) => _buildCard(
        context,
        rates: _fallback,
        isLive: false,
        allRates: _fallback,
      ),
      data: (rates) {
        final list = rates.isNotEmpty ? rates : _fallback;
        return _buildCard(context, rates: list, isLive: false, allRates: list);
      },
    );
  }

  static Widget _buildShimmer() => Shimmer.fromColors(
    baseColor: AppColors.bgCard,
    highlightColor: AppColors.bgTertiary,
    child: Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _buildCard(
    BuildContext context, {
    required List<FundingRate> rates,
    required bool isLive,
    required List<FundingRate> allRates,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Funding Rates',
                  subtitle: 'Perpetual futures · 8h intervals',
                ),
              ),
              if (isLive) ...[
                const NeonBadge(label: 'LIVE', color: AppColors.brandGreen),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: () => _showAllRates(context, allRates),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rates.map((r) => _FundingRow(
            symbol: r.symbol,
            rate: r.rate,
            positive: r.positive,
            formatted: r.formatted,
            isHigh: r.isHigh,
            interpretation: r.interpretation,
            onTap: () => _showRateHistory(context, r.symbol),
          )),
        ],
      ),
    );
  }

  void _showAllRates(BuildContext context, List<FundingRate> rates) {
    final sorted = [...rates]..sort((a, b) => b.rate.abs().compareTo(a.rate.abs()));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (innerCtx, scrollController) => _AllRatesContent(
          fallbackRates: sorted,
          scrollController: scrollController,
          onRowTap: (symbol) => _showRateHistory(context, symbol),
        ),
      ),
    );
  }

  void _showRateHistory(BuildContext context, String symbol) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(symbol, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Text('Funding History', style: TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (ctx, ref, _) {
                    final history = ref.watch(fundingHistoryProvider(symbol));
                    return history.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.brandGreen, strokeWidth: 2)),
                      error: (e, _) => Center(
                        child: Text('No history for $symbol',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Text('No history for $symbol',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)));
                        }

                        final now = DateTime.now();

                        // Parse all entries
                        final parsed = <_HistoryEntry>[];
                        for (final item in items) {
                          final raw = item['fundingRate'] ?? item['rate'] ?? item['funding_rate'] ?? 0.0;
                          final rateVal = double.tryParse(raw.toString()) ?? 0.0;
                          final tsRaw = item['fundingTime'] ?? item['timestamp'] ?? item['time'] ?? item['created_at'];
                          DateTime? dt;
                          if (tsRaw != null) {
                            try {
                              dt = tsRaw is int
                                  ? DateTime.fromMillisecondsSinceEpoch(tsRaw).toLocal()
                                  : DateTime.parse(tsRaw.toString()).toLocal();
                            } catch (_) {}
                          }
                          parsed.add(_HistoryEntry(dt: dt, rateVal: rateVal));
                        }

                        // Sort newest first
                        parsed.sort((a, b) {
                          if (a.dt == null) return 1;
                          if (b.dt == null) return -1;
                          return b.dt!.compareTo(a.dt!);
                        });

                        // Build sectioned list
                        final today = DateTime(now.year, now.month, now.day);
                        final yesterday = today.subtract(const Duration(days: 1));
                        final widgets = <Widget>[];
                        String? lastSection;

                        for (final p in parsed) {
                          String section;
                          if (p.dt == null) {
                            section = 'Unknown';
                          } else {
                            final day = DateTime(p.dt!.year, p.dt!.month, p.dt!.day);
                            if (day == today) {
                              section = 'Today';
                            } else if (day == yesterday) {
                              section = 'Yesterday';
                            } else {
                              section = '${p.dt!.day} ${_month(p.dt!.month)}';
                            }
                          }

                          if (section != lastSection) {
                            lastSection = section;
                            if (widgets.isNotEmpty) {
                              widgets.add(const SizedBox(height: 4));
                              widgets.add(const Divider(color: AppColors.borderSubtle, height: 1));
                            }
                            widgets.add(Padding(
                              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                              child: Text(section,
                                style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted, letterSpacing: 0.8)),
                            ));
                          }

                          final positive = p.rateVal >= 0;
                          final color = positive ? AppColors.brandGreen : AppColors.brandRed;
                          final formatted = '${positive ? '+' : ''}${(p.rateVal * 100).toStringAsFixed(4)}%';

                          widgets.add(Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.dt != null ? _relativeTime(p.dt!, now) : '—',
                                        style: const TextStyle(
                                          fontSize: 12, color: Colors.white,
                                          fontFamily: 'JetBrainsMono'),
                                      ),
                                      if (p.dt != null)
                                        Text(
                                          _clockTime(p.dt!),
                                          style: const TextStyle(
                                            fontSize: 9, color: AppColors.textMuted,
                                            fontFamily: 'JetBrainsMono'),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(formatted,
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: color, fontFamily: 'JetBrainsMono')),
                              ],
                            ),
                          ));
                        }

                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          children: widgets,
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

  static String _relativeTime(DateTime dt, DateTime now) {
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  static String _clockTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _month(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  static final _fallback = [
    const FundingRate(symbol: 'BTCUSDT', rate: 0.00023),
    const FundingRate(symbol: 'ETHUSDT', rate: 0.00018),
    const FundingRate(symbol: 'SOLUSDT', rate: -0.00008),
    const FundingRate(symbol: 'BNBUSDT', rate: 0.00031),
    const FundingRate(symbol: 'ARBUSDT', rate: 0.00045),
  ];
}

// ── All-rates sheet content ───────────────────────────────────────────────────

class _AllRatesContent extends ConsumerStatefulWidget {
  final List<FundingRate> fallbackRates;
  final ScrollController scrollController;
  final void Function(String symbol) onRowTap;

  const _AllRatesContent({
    required this.fallbackRates,
    required this.scrollController,
    required this.onRowTap,
  });

  @override
  ConsumerState<_AllRatesContent> createState() => _AllRatesContentState();
}

class _AllRatesContentState extends ConsumerState<_AllRatesContent> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allFundingRatesProvider);
    final isLoading = allAsync.isLoading;
    final allRates = allAsync.valueOrNull?.isNotEmpty == true
        ? allAsync.valueOrNull!
        : widget.fallbackRates;
    final sorted = [...allRates]..sort((a, b) => b.rate.abs().compareTo(a.rate.abs()));
    final filtered = _query.isEmpty
        ? sorted
        : sorted.where((r) => r.symbol.toLowerCase().contains(_query.toLowerCase())).toList();

    return Container(
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
              child: Text('All Funding Rates',
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
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search coin...',
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen, strokeWidth: 2))
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'No rates available' : 'No results for "$_query"',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      return _FundingRow(
                        symbol: r.symbol,
                        rate: r.rate,
                        positive: r.positive,
                        formatted: r.formatted,
                        isHigh: r.isHigh,
                        interpretation: r.interpretation,
                        onTap: () => widget.onRowTap(r.symbol),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry {
  final DateTime? dt;
  final double rateVal;
  const _HistoryEntry({this.dt, required this.rateVal});
}

class _FundingRow extends StatelessWidget {
  final String symbol;
  final double rate;
  final bool positive;
  final String formatted;
  final bool isHigh;
  final String interpretation;
  final VoidCallback? onTap;

  const _FundingRow({
    required this.symbol,
    required this.rate,
    required this.positive,
    required this.formatted,
    required this.isHigh,
    required this.interpretation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.brandGreen : AppColors.brandRed;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(symbol,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      if (isHigh) ...[
                        const SizedBox(width: 6),
                        const NeonBadge(label: 'HIGH', color: AppColors.brandAmber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(interpretation,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(formatted,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'JetBrainsMono',
              )),
          ],
        ),
      ),
    );
  }
}
