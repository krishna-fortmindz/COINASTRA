import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
// import '../../core/widgets/glass_card.dart';
// import '../../providers/token_unlocks_provider.dart';

class TokenUnlocksScreen extends StatelessWidget {
  const TokenUnlocksScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon(
        icon: Icons.lock_open_rounded,
        title: 'Token Unlocks',
        subtitle: 'Monitor upcoming token unlock events and\nvesting schedules. Launching very soon.',
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

class _TokenUnlocksScreenOld extends ConsumerStatefulWidget {
  const _TokenUnlocksScreenOld({super.key});

  @override
  ConsumerState<_TokenUnlocksScreenOld> createState() => _TokenUnlocksScreenState();
}

class _TokenUnlocksScreenState extends ConsumerState<TokenUnlocksScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<TokenUnlock> _filtered(List<TokenUnlock> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((u) =>
      u.symbol.toLowerCase().contains(q) ||
      u.name.toLowerCase().contains(q) ||
      (u.category?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(upcomingUnlocksProvider);

    // Search bar lives OUTSIDE asyncData.when so it never rebuilds from scratch
    // on query changes — preserving focus on Flutter web.
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Always-stable header + search ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStatic(asyncData),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // ── Async content ───────────────────────────────────────
          Expanded(
            child: asyncData.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandAmber),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.brandRed, size: 40),
                    const SizedBox(height: 12),
                    const Text('Failed to load token unlocks',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(e.toString(),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(upcomingUnlocksProvider),
                      child: const Text('Retry', style: TextStyle(color: AppColors.brandAmber)),
                    ),
                  ],
                ),
              ),
              data: (unlocks) {
                final filtered = _filtered(unlocks);
                final highRisk = unlocks.where((u) => u.riskLevel == 'HIGH' || u.riskLevel == 'EXTREME').length;
                final totalUsd = unlocks.fold<double>(0, (sum, u) => sum + (u.valueUsd ?? 0));
                final biggest = unlocks.isEmpty
                    ? null
                    : unlocks.reduce((a, b) => (a.supplyPct ?? 0) >= (b.supplyPct ?? 0) ? a : b);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_query.isEmpty) ...[
                              _buildSummaryRow(totalUsd, highRisk, biggest),
                              const SizedBox(height: 20),
                              _buildTimeline(unlocks),
                              const SizedBox(height: 20),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _query.isEmpty
                                      ? 'Upcoming Unlocks (${unlocks.length})'
                                      : '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                                    style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => ref.invalidate(upcomingUnlocksProvider),
                                  child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: filtered.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  _query.isEmpty ? 'No upcoming unlocks' : 'No unlocks found for "$_query"',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UnlockCard(unlock: filtered[i]),
                              ),
                              childCount: filtered.length,
                            ),
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatic(AsyncValue<List<TokenUnlock>> asyncData) {
    final count = asyncData.value?.length ?? 0;
    final totalUsd = asyncData.value?.fold<double>(0, (s, u) => s + (u.valueUsd ?? 0)) ?? 0;
    return _buildHeader(count, totalUsd);
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          ),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by coin, name or category...',
                hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, double totalUsd) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Token Unlocks', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                letterSpacing: -0.5,
              )),
              Text('Vesting schedule · Price impact · Risk assessment',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        NeonBadge(label: '$count upcoming', color: AppColors.brandAmber),
      ],
    );
  }

  Widget _buildSummaryRow(double totalUsd, int highRisk, TokenUnlock? biggest) {
    final totalLabel = _formatUsd(totalUsd);
    final biggestLabel = biggest?.symbol ?? '—';
    final biggestSub = biggest != null && biggest.supplyPct != null
        ? '${biggest.supplyPct!.toStringAsFixed(1)}% supply'
        : '—';

    return Row(
      children: [
        Expanded(child: _SummaryTile(totalLabel, 'Total Unlock Value', '30 days', AppColors.brandAmber)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryTile('$highRisk', 'High Risk Events', 'Monitor closely', AppColors.brandRed)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryTile(biggestLabel, 'Biggest Risk', biggestSub, AppColors.brandRed)),
      ],
    );
  }

  Widget _buildTimeline(List<TokenUnlock> unlocks) {
    final timelineItems = unlocks.take(6).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unlock Timeline (Next 30 Days)', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          const SizedBox(height: 16),
          ...timelineItems.map((u) {
            final daysStr = u.daysLeft != null ? '${u.daysLeft} days' : _formatDate(u.unlockDate);
            final emojiStr = u.emoji ?? (u.symbol.isNotEmpty ? u.symbol[0] : '?');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(daysStr, style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('$emojiStr ${u.symbol}', style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
                            )),
                            const Spacer(),
                            Text(
                              u.valueUsd != null ? _formatUsd(u.valueUsd!) : '—',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: _riskColor(u.riskLevel),
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ((u.supplyPct ?? 0) / 10).clamp(0.0, 1.0),
                            backgroundColor: AppColors.borderSubtle,
                            valueColor: AlwaysStoppedAnimation(_riskColor(u.riskLevel)),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
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

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('MMM d, y').format(dt);
}

String _formatUsd(double v) {
  if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
  if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
  return '\$${v.toStringAsFixed(0)}';
}

Color _riskColor(String risk) {
  switch (risk) {
    case 'EXTREME': return AppColors.brandRed;
    case 'HIGH': return AppColors.brandAmber;
    case 'MEDIUM': return AppColors.brandBlue;
    default: return AppColors.brandGreen;
  }
}

class _SummaryTile extends StatelessWidget {
  final String value, label, sub;
  final Color color;
  const _SummaryTile(this.value, this.label, this.sub, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900,
            color: color, fontFamily: 'JetBrainsMono',
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final TokenUnlock unlock;
  const _UnlockCard({required this.unlock});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(unlock.riskLevel);
    final emojiStr = unlock.emoji ?? (unlock.symbol.isNotEmpty ? unlock.symbol[0] : '?');
    final dateStr = _formatDate(unlock.unlockDate);
    final daysStr = unlock.daysLeft != null ? '${unlock.daysLeft} days' : '—';
    final usdStr = unlock.valueUsd != null ? _formatUsd(unlock.valueUsd!) : '—';
    final supplyStr = unlock.supplyPct != null ? '${unlock.supplyPct!.toStringAsFixed(1)}%' : '—';

    return GlassCard(
      borderColor: color.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(child: Text(emojiStr,
                  style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(unlock.symbol, style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                        )),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(unlock.riskLevel, style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700, color: color,
                          )),
                        ),
                      ],
                    ),
                    Text(
                      '${unlock.name}${unlock.category != null ? ' · ${unlock.category}' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(usdStr, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.white, fontFamily: 'JetBrainsMono',
                  )),
                  Text(dateStr, style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _UnlockStat('Amount', unlock.amount, AppColors.textMuted),
              const SizedBox(width: 8),
              _UnlockStat('% Supply', supplyStr, color),
              const SizedBox(width: 8),
              _UnlockStat('In', daysStr, AppColors.brandBlue),
              const SizedBox(width: 8),
              _UnlockStat('Est. Impact', unlock.priceImpact ?? '—', color),
            ],
          ),
          if (unlock.notes != null && unlock.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 13, color: AppColors.brandAmber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(unlock.notes!, style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, height: 1.5,
                  )),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlockStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _UnlockStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textDisabled)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color,
            )),
          ],
        ),
      ),
    );
  }
}

─────────────────────────────────────────────────────────────────────────── */
