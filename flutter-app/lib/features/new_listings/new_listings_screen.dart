import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
// import '../../core/widgets/glass_card.dart';
// import '../../core/remote/data/new_listings/models/new_listings_models.dart';
// import '../../providers/new_listings_provider.dart';
// import '../../providers/ai_analysis_provider.dart';

// const _filters = ['All', 'AI', 'Meme', 'DeFi', 'Gaming', 'RWA'];

class NewListingsScreen extends StatelessWidget {
  const NewListingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon(
        icon: Icons.new_releases_rounded,
        title: 'New Listings',
        subtitle: 'Track newly listed tokens across major exchanges.\nLaunching very soon.',
      );
}

class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ComingSoon({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 32, color: AppColors.brandGreen),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
              ),
              child: const Text('COMING SOON', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.brandGreen, letterSpacing: 1.4,
              )),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(
              fontSize: 14, color: AppColors.textMuted, height: 1.6,
            )),
          ],
        ),
      ),
    );
  }
}

/* ── Original screen (temporarily disabled) ────────────────────────────────

class _NewListingsScreenOld extends ConsumerStatefulWidget {
  const _NewListingsScreenOld({super.key});

  @override
  ConsumerState<_NewListingsScreenOld> createState() => _NewListingsScreenState();
}

class _NewListingsScreenState extends ConsumerState<_NewListingsScreenOld> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  // Header rebuilds when listing count changes
                  Consumer(
                    builder: (_, ref, __) {
                      final count = ref.watch(
                        newListingsProvider
                            .select((s) => s.listings.valueOrNull?.length ?? 0),
                      );
                      return _Header(count: count);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white),
                            onChanged: (v) => ref
                                .read(newListingsProvider.notifier)
                                .setSearch(v),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or symbol...',
                              hintStyle: TextStyle(
                                  color: AppColors.textDisabled, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Consumer(
                          builder: (_, ref, __) {
                            final query = ref.watch(newListingsProvider
                                .select((s) => s.searchQuery));
                            if (query.isEmpty) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref
                                    .read(newListingsProvider.notifier)
                                    .setSearch('');
                              },
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textMuted),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Only filter row rebuilds when filter changes
                  Consumer(
                    builder: (_, ref, __) {
                      final filter = ref.watch(
                        newListingsProvider.select((s) => s.filter),
                      );
                      return _FilterRow(
                        filters: _filters,
                        selected: filter,
                        onChanged: (f) =>
                            ref.read(newListingsProvider.notifier).setFilter(f),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // List rebuilds when listings / aiScores / search changes
          Consumer(
            builder: (_, ref, __) {
              final state = ref.watch(newListingsProvider);

              if (state.listings.isLoading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              if (state.listings.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.brandRed, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            state.listings.error?.toString() ??
                                'Failed to load listings',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                ref.read(newListingsProvider.notifier).refresh(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.brandGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.brandGreen.withAlpha(60)),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.brandGreen,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final displayList = state.displayList;

              if (displayList.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Center(
                      child: Text(
                        state.searchQuery.isNotEmpty
                            ? 'No listings found for "${state.searchQuery}"'
                            : 'No listings available',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ListingCard(
                        listing: displayList[i],
                        aiScore: state.aiScores[displayList[i].coinId],
                        onTap: () {
                          ref
                              .read(aiAnalysisProvider)
                              .selectCoin(displayList[i].symbol);
                          context.go('/analysis');
                        },
                      ),
                    ),
                    childCount: displayList.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Listings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Binance & Bybit · AI early momentum detection',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        const NeonBadge(
            label: 'LIVE', color: AppColors.brandGreen, icon: Icons.circle),
        const SizedBox(width: 8),
        NeonBadge(
            label: '$count listed', color: AppColors.brandAmber),
      ],
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((f) => GestureDetector(
                  onTap: () => onChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected == f
                          ? AppColors.brandGreen.withAlpha(20)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == f
                            ? AppColors.brandGreen.withAlpha(60)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected == f
                            ? AppColors.brandGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final NewListing listing;
  final AiListingScore? aiScore;
  final VoidCallback? onTap;

  const _ListingCard({
    required this.listing,
    required this.aiScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = listing.riskLevel == 'High'
        ? AppColors.brandRed
        : listing.riskLevel == 'Medium'
            ? AppColors.brandAmber
            : AppColors.brandGreen;

    const narrativeColor = {
      'Meme': AppColors.brandGreen,
      'AI': AppColors.brandPurple,
      'DeFi': AppColors.brandBlue,
      'Gaming': AppColors.brandCyan,
      'RWA': AppColors.brandAmber,
    };

    final aiScoreValue =
        aiScore != null ? aiScore!.score : listing.potentialScore;
    final aiReason =
        aiScore != null ? aiScore!.summary : 'Analyzing...';

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(
                  child: listing.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            listing.imageUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              listing.categoryEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        )
                      : Text(
                          listing.categoryEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          listing.symbol,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (narrativeColor[listing.category] ??
                                    AppColors.brandGreen)
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            listing.category,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: narrativeColor[listing.category] ??
                                  AppColors.brandGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${listing.name} · ${listing.exchange}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    listing.formattedPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  Text(
                    listing.formattedChange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: listing.change24h >= 0
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Score('Social', listing.socialSentiment, AppColors.brandBlue),
              const SizedBox(width: 8),
              _Score(
                  'Momentum', listing.momentumScore, AppColors.brandAmber),
              const SizedBox(width: 8),
              _Score('AI Score', aiScoreValue, AppColors.brandGreen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                  'Vol Surge', listing.formattedVolumeSurge, AppColors.brandCyan),
              const SizedBox(width: 8),
              _StatPill('Listed', listing.listingDate, AppColors.textMuted),
              const SizedBox(width: 8),
              _StatPill('Risk', listing.riskLevel, riskColor),
              if (listing.whaleActivity) ...[
                const SizedBox(width: 8),
                const _StatPill('🐋 Whale', 'Active', AppColors.brandPurple),
              ],
              if (listing.smartMoney) ...[
                const SizedBox(width: 8),
                const _StatPill('🏦 Smart', 'Money', AppColors.brandGreen),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.black, size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this coin may have potential:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aiReason,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Score Bar ─────────────────────────────────────────────────────────────────

class _Score extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Score(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(25)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 8, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

─────────────────────────────────────────────────────────────────────────── */
