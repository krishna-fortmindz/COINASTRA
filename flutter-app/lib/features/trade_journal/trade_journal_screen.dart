import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../core/remote/data/journal/journal_models.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/journal_provider.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class TradeJournalScreen extends ConsumerStatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  ConsumerState<TradeJournalScreen> createState() =>
      _TradeJournalScreenState();
}

class _TradeJournalScreenState extends ConsumerState<TradeJournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openLogTrade([JournalEntry? entry]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogTradeSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(journalStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLogTrade(),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _JournalHeader(
            tabController: _tabs,
            winRate: stats.valueOrNull?.winRate,
            totalPnl: stats.valueOrNull?.totalPnl,
            totalTrades: stats.valueOrNull?.totalTrades,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TradesTab(onEdit: _openLogTrade),
                const _AnalyticsTab(),
                const _PsychologyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _JournalHeader extends StatelessWidget {
  final TabController tabController;
  final double? winRate;
  final double? totalPnl;
  final int? totalTrades;

  const _JournalHeader({
    required this.tabController,
    this.winRate,
    this.totalPnl,
    this.totalTrades,
  });

  @override
  Widget build(BuildContext context) {
    final pnlPositive = (totalPnl ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trade Journal',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Text('Track, analyze & improve your trading',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBadge(
                'Win Rate',
                winRate != null ? '${winRate!.toStringAsFixed(0)}%' : '—',
                AppColors.brandGreen,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                'P&L',
                totalPnl != null
                    ? '${pnlPositive ? '+' : ''}\$${totalPnl!.toStringAsFixed(0)}'
                    : '—',
                pnlPositive ? AppColors.brandGreen : AppColors.brandRed,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                'Trades',
                totalTrades?.toString() ?? '—',
                AppColors.brandBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.brandGreen,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.brandGreen,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Trade Log'),
              Tab(text: 'Analytics'),
              Tab(text: 'AI Psychology'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'JetBrainsMono')),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Trades Tab ────────────────────────────────────────────────────────────────

class _TradesTab extends ConsumerWidget {
  final void Function(JournalEntry) onEdit;
  const _TradesTab({required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);
    final filter = ref.watch(journalFilterProvider);

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                active: filter.direction == null,
                onTap: () => ref.read(journalFilterProvider.notifier).state =
                    const JournalFilter(),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Long',
                active: filter.direction == 'Long',
                color: AppColors.brandGreen,
                onTap: () => ref.read(journalFilterProvider.notifier).state =
                    const JournalFilter(direction: 'Long'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Short',
                active: filter.direction == 'Short',
                color: AppColors.brandRed,
                onTap: () => ref.read(journalFilterProvider.notifier).state =
                    const JournalFilter(direction: 'Short'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: entries.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.brandGreen, strokeWidth: 2),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 8),
                  Text(e.toString(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.read(journalProvider.notifier).refresh(),
                    child: const Text('Retry',
                        style: TextStyle(color: AppColors.brandGreen)),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? const _EmptyTradeState()
                : RefreshIndicator(
                    color: AppColors.brandGreen,
                    backgroundColor: AppColors.bgSecondary,
                    onRefresh: () =>
                        ref.read(journalProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _TradeCard(
                        entry: list[i],
                        onEdit: () => onEdit(list[i]),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color = AppColors.brandGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(25) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withAlpha(80) : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? color : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _TradeCard extends ConsumerWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  const _TradeCard({required this.entry, required this.onEdit});

  static const _emotionEmoji = {
    'calm': '😌',
    'confident': '💪',
    'patient': '🧘',
    'nervous': '😰',
    'fomo': '🚀',
    'revenge': '😤',
    'disciplined': '🎯',
  };

  Color _emotionColor(String? e) {
    switch (e) {
      case 'calm':
      case 'confident':
      case 'patient':
      case 'disciplined':
        return AppColors.brandGreen;
      case 'fomo':
      case 'revenge':
        return AppColors.brandRed;
      default:
        return AppColors.brandAmber;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLong = entry.direction.toLowerCase() == 'long';
    final dirColor = isLong ? AppColors.brandGreen : AppColors.brandRed;
    final pnl = entry.pnlUsd;
    final pnlPositive = (pnl ?? 0) >= 0;
    final emotionColor = _emotionColor(entry.psychology);
    final emoji = _emotionEmoji[entry.psychology] ?? '🤔';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.brandRed.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brandRed.withAlpha(30)),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.brandRed),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.bgSecondary,
                title: const Text('Delete Trade',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                content: Text('Remove ${entry.pair} from your journal?',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.brandRed)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(journalProvider.notifier).deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.pair} trade deleted'),
            backgroundColor: AppColors.bgSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GlassCard(
        onTap: onEdit,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dirColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLong
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: dirColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.pair,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(width: 6),
                      if (entry.psychology != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: emotionColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$emoji ${_capitalize(entry.psychology!)}',
                            style: TextStyle(
                                fontSize: 9, color: emotionColor),
                          ),
                        ),
                      if (entry.isOpen) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('OPEN',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.exitPrice != null
                        ? 'Entry \$${entry.entryPrice.toStringAsFixed(2)} → Exit \$${entry.exitPrice!.toStringAsFixed(2)}'
                        : 'Entry \$${entry.entryPrice.toStringAsFixed(2)} · Size \$${entry.size.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontFamily: 'JetBrainsMono'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pnl != null)
                  Text(
                    '${pnlPositive ? '+' : ''}\$${pnl.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pnlPositive
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      fontFamily: 'JetBrainsMono',
                    ),
                  )
                else
                  const Text('—',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textMuted)),
                Text(
                  _timeAgo(entry.createdAt ?? entry.entryAt),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textDisabled),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _EmptyTradeState extends StatelessWidget {
  const _EmptyTradeState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.book_rounded,
                color: AppColors.brandGreen, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('No trades yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Tap + to log your first trade',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Analytics Tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(journalStatsProvider);

    return stats.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.brandGreen, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load analytics',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(journalStatsProvider),
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.brandGreen)),
            ),
          ],
        ),
      ),
      data: (s) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Win Rate',
                    value: '${s.winRate.toStringAsFixed(0)}%',
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.brandGreen,
                    valueColor: AppColors.brandGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Profit Factor',
                    value: '${s.profitFactor.toStringAsFixed(1)}x',
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Avg R:R',
                    value: '1:${s.avgRr.toStringAsFixed(1)}',
                    icon: Icons.balance_rounded,
                    iconColor: AppColors.brandAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (s.totalPnl >= 0
                              ? AppColors.brandGreen
                              : AppColors.brandRed)
                          .withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      s.totalPnl >= 0
                          ? Icons.account_balance_wallet_rounded
                          : Icons.trending_down_rounded,
                      color: s.totalPnl >= 0
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Total P&L',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                  const Spacer(),
                  Text(
                    '${s.totalPnl >= 0 ? '+' : ''}\$${s.totalPnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: s.totalPnl >= 0
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (s.psychologyPatterns.isNotEmpty)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Win Rate by Psychology',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    ...s.psychologyPatterns.map((p) => _EmotionBar(
                          emotion: p.psychology,
                          winRate: p.winRate,
                          trades: p.trades,
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmotionBar extends StatelessWidget {
  final String emotion;
  final double winRate;
  final int trades;

  const _EmotionBar({
    required this.emotion,
    required this.winRate,
    required this.trades,
  });

  Color get _color {
    if (winRate >= 60) return AppColors.brandGreen;
    if (winRate >= 40) return AppColors.brandAmber;
    return AppColors.brandRed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(_capitalize(emotion),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              Text('$trades trades',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textDisabled)),
              const SizedBox(width: 12),
              Text('${winRate.toStringAsFixed(0)}% WR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _color,
                    fontFamily: 'JetBrainsMono',
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (winRate / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Psychology Tab ────────────────────────────────────────────────────────────

class _PsychologyTab extends ConsumerWidget {
  const _PsychologyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(journalStatsProvider);

    return stats.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.brandGreen, strokeWidth: 2),
      ),
      error: (_, __) => const Center(
        child: Text('Could not load psychology insights',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ),
      data: (s) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassCard(
              borderColor: AppColors.brandPurple.withAlpha(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: AppColors.brandPurple, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('AI Psychology Insights',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (s.aiInsights.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Log more trades to unlock AI psychology analysis.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted, height: 1.5),
                      ),
                    )
                  else
                    ...s.aiInsights.map((insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.brandAmber.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 12,
                                    color: AppColors.brandAmber),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(insight,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      height: 1.5,
                                    )),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            if (s.psychologyPatterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Psychology Distribution',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: s.psychologyPatterns
                          .map((p) => _PsychologyChip(pattern: p))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PsychologyChip extends StatelessWidget {
  final PsychologyPattern pattern;
  const _PsychologyChip({required this.pattern});

  static const _emotionEmoji = {
    'calm': '😌',
    'confident': '💪',
    'patient': '🧘',
    'nervous': '😰',
    'fomo': '🚀',
    'revenge': '😤',
    'disciplined': '🎯',
  };

  Color get _color {
    switch (pattern.psychology) {
      case 'calm':
      case 'confident':
      case 'patient':
      case 'disciplined':
        return AppColors.brandGreen;
      case 'fomo':
      case 'revenge':
        return AppColors.brandRed;
      default:
        return AppColors.brandAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final emoji = _emotionEmoji[pattern.psychology] ?? '🤔';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$emoji ${_capitalize(pattern.psychology)}',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${pattern.trades} trades · ${pattern.winRate.toStringAsFixed(0)}% WR',
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Log Trade Sheet ───────────────────────────────────────────────────────────

class _LogTradeSheet extends ConsumerStatefulWidget {
  final JournalEntry? entry; // non-null = edit mode

  const _LogTradeSheet({this.entry});

  @override
  ConsumerState<_LogTradeSheet> createState() => _LogTradeSheetState();
}

class _LogTradeSheetState extends ConsumerState<_LogTradeSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pairCtrl;
  late TextEditingController _entryCtrl;
  late TextEditingController _exitCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _strategyCtrl;
  late TextEditingController _notesCtrl;

  String _direction = 'long';
  String _psychology = 'calm';
  bool _loading = false;
  String _pairSearchQuery = '';

  static const _psychologies = [
    'calm', 'confident', 'patient', 'nervous', 'fomo', 'revenge', 'disciplined',
  ];

  static const _emotionEmoji = {
    'calm': '😌',
    'confident': '💪',
    'patient': '🧘',
    'nervous': '😰',
    'fomo': '🚀',
    'revenge': '😤',
    'disciplined': '🎯',
  };

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _pairCtrl = TextEditingController(text: e?.pair ?? '');
    _entryCtrl = TextEditingController(
        text: e != null ? e.entryPrice.toStringAsFixed(2) : '');
    _exitCtrl = TextEditingController(
        text: e?.exitPrice != null ? e!.exitPrice!.toStringAsFixed(2) : '');
    _sizeCtrl = TextEditingController(
        text: e != null ? e.size.toStringAsFixed(0) : '');
    _strategyCtrl = TextEditingController(text: e?.strategy ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _direction = e.direction;
      _psychology = e.psychology ?? 'calm';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _pairCtrl, _entryCtrl, _exitCtrl, _sizeCtrl, _strategyCtrl, _notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = <String, dynamic>{
      'pair': _pairCtrl.text.trim().toUpperCase(),
      'direction': _direction == 'long' ? 'Long' : 'Short',
      'entryPrice': double.parse(_entryCtrl.text.replaceAll(',', '')),
      if (_exitCtrl.text.isNotEmpty)
        'exitPrice': double.parse(_exitCtrl.text.replaceAll(',', '')),
      'positionSize': double.parse(_sizeCtrl.text.replaceAll(',', '')),
      'psychology': _psychology,
      if (_strategyCtrl.text.isNotEmpty) 'strategy': _strategyCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await ref
            .read(journalProvider.notifier)
            .updateEntry(widget.entry!.id, data);
      } else {
        await ref.read(journalProvider.notifier).addEntry(data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Trade updated' : 'Trade logged'),
            backgroundColor: AppColors.bgSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.brandRed.withAlpha(200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: 60, bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  _isEdit ? 'Edit Trade' : 'Log Trade',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pair search
                    _SheetField(
                      label: 'Pair',
                      controller: _pairCtrl,
                      hint: 'Search coin or type e.g. BTC/USDT',
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Required' : null,
                      onChanged: (v) => setState(() => _pairSearchQuery = v),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 16, color: AppColors.textMuted),
                    ),
                    if (_pairSearchQuery.length >= 2)
                      Consumer(builder: (_, ref, __) {
                        final results =
                            ref.watch(coinSearchProvider(_pairSearchQuery));
                        return results.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: AppColors.brandGreen,
                                    strokeWidth: 2),
                              ),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (coins) => coins.isEmpty
                              ? const SizedBox.shrink()
                              : _CoinSearchDropdown(
                                  coins: coins,
                                  onSelect: (pair) => setState(() {
                                    _pairCtrl.text = pair;
                                    _pairSearchQuery = '';
                                  }),
                                ),
                        );
                      }),
                    const SizedBox(height: 12),

                    // Direction toggle
                    const Text('Direction',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _DirectionBtn(
                            label: 'LONG',
                            icon: Icons.trending_up_rounded,
                            selected: _direction == 'long',
                            color: AppColors.brandGreen,
                            onTap: () =>
                                setState(() => _direction = 'long'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DirectionBtn(
                            label: 'SHORT',
                            icon: Icons.trending_down_rounded,
                            selected: _direction == 'short',
                            color: AppColors.brandRed,
                            onTap: () =>
                                setState(() => _direction = 'short'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Entry / Exit / Size row
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            label: 'Entry Price',
                            controller: _entryCtrl,
                            hint: '0.00',
                            prefix: '\$',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SheetField(
                            label: 'Exit Price (opt.)',
                            controller: _exitCtrl,
                            hint: '0.00',
                            prefix: '\$',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SheetField(
                            label: 'Size (USDT)',
                            controller: _sizeCtrl,
                            hint: '500',
                            prefix: '\$',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Psychology
                    const Text('Psychology / Mood',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _psychologies
                          .map((p) => GestureDetector(
                                onTap: () =>
                                    setState(() => _psychology = p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _psychology == p
                                        ? AppColors.brandGreen.withAlpha(25)
                                        : AppColors.bgCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _psychology == p
                                          ? AppColors.brandGreen.withAlpha(80)
                                          : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    '${_emotionEmoji[p]} ${_capitalize(p)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _psychology == p
                                          ? AppColors.brandGreen
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),

                    // Strategy + Notes
                    _SheetField(
                      label: 'Strategy (opt.)',
                      controller: _strategyCtrl,
                      hint: 'Breakout, Support bounce…',
                    ),
                    const SizedBox(height: 10),
                    _SheetField(
                      label: 'Notes (opt.)',
                      controller: _notesCtrl,
                      hint: 'What went well? What to improve?',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                _isEdit ? 'Update Trade' : 'Log Trade',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DirectionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withAlpha(80) : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final String hint;
  final String? prefix;
  final Widget? prefixIcon;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.prefix,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: prefixIcon,
            prefixIconConstraints:
                prefixIcon != null ? const BoxConstraints(minWidth: 36) : null,
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 12, color: AppColors.textDisabled),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandGreen),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandRed),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Coin search dropdown ──────────────────────────────────────────────────────

class _CoinSearchDropdown extends StatelessWidget {
  final List<MarketCoin> coins;
  final ValueChanged<String> onSelect;

  const _CoinSearchDropdown({required this.coins, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: coins.take(6).toList().asMap().entries.map((e) {
          final isLast = e.key == (coins.length > 6 ? 5 : coins.length - 1);
          final coin = e.value;
          final pair = '${coin.symbol.toUpperCase()}/USDT';
          return GestureDetector(
            onTap: () => onSelect(pair),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        coin.symbol.isNotEmpty
                            ? coin.symbol[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pair,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(coin.name,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text(
                    coin.currentPrice >= 1000
                        ? '\$${coin.currentPrice.toStringAsFixed(0)}'
                        : '\$${coin.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        fontFamily: 'JetBrainsMono'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
