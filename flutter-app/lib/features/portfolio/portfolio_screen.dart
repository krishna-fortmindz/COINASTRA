import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/remote/data/dashboard/models/dashboard_models.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _Header(tabs: _tabs),
          if (s.error != null) _ErrorBanner(message: s.error!),
          _TotalsCard(totals: s.totals, currency: s.currency, isLoading: s.isLoading),
          _TabBar(tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PositionsList(
                  positions: s.openPositions,
                  isLoading: s.isLoading,
                  currency: s.currency,
                  isOpen: true,
                  tips: s.tips,
                  tipsLoading: s.tipsLoading,
                ),
                _PositionsList(
                  positions: s.closedPositions,
                  isLoading: s.isLoading,
                  currency: s.currency,
                  isOpen: false,
                  tips: null,
                  tipsLoading: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final TabController tabs;
  const _Header({required this.tabs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(portfolioProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                Text('Live positions · P&L · ROE',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Currency toggle
          GestureDetector(
            onTap: () => ref.read(portfolioProvider.notifier).toggleCurrency(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.currency == 'USD' ? '\$' : '₹',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreen),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.currency,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => ref.read(portfolioProvider.notifier).fetch(),
            icon: s.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brandGreen))
                : const Icon(Icons.refresh_rounded,
                    color: AppColors.textMuted),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ────────────────────────────────────────────────────────────────

class _ErrorBanner extends ConsumerWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandRed.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandRed.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 14, color: AppColors.brandRed),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.brandRed))),
          GestureDetector(
            onTap: () => ref.read(portfolioProvider.notifier).clearError(),
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.brandRed),
          ),
        ],
      ),
    );
  }
}

// ── Totals Card ────────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final PortfolioTotals totals;
  final String currency;
  final bool isLoading;
  const _TotalsCard(
      {required this.totals,
      required this.currency,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final inr = currency == 'INR';
    final pnl = inr ? (totals.totalPnlInr ?? totals.totalPnlUsd) : totals.totalPnlUsd;
    final value = inr ? (totals.totalValueInr ?? totals.totalValueUsd) : totals.totalValueUsd;
    final margin = inr ? (totals.totalMarginInr ?? totals.totalMarginUsd) : totals.totalMarginUsd;
    final symbol = inr ? '₹' : '\$';
    final positive = pnl >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassCard(
        borderColor: positive
            ? AppColors.brandGreen.withAlpha(30)
            : AppColors.brandRed.withAlpha(30),
        child: isLoading && totals.positionCount == 0
            ? const SizedBox(
                height: 60,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brandGreen)))
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Position Value',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '$symbol${_fmt(value)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'JetBrainsMono',
                                  letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                positive
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 12,
                                color: positive
                                    ? AppColors.brandGreen
                                    : AppColors.brandRed,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${positive ? '+' : ''}$symbol${_fmt(pnl.abs())} (${totals.totalPnlPct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: positive
                                      ? AppColors.brandGreen
                                      : AppColors.brandRed,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Margin: $symbol${_fmt(margin)} · ${totals.positionCount} open',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

// ── Tab Bar ─────────────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  final TabController tabs;
  const _TabBar({required this.tabs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(portfolioProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TabBar(
        controller: tabs,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.brandGreen.withAlpha(20),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.brandGreen.withAlpha(60)),
        ),
        dividerColor: Colors.transparent,
        labelColor: AppColors.brandGreen,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Open (${s.openPositions.length})'),
          Tab(text: 'Closed (${s.closedPositions.length})'),
        ],
      ),
    );
  }
}

// ── Positions List ──────────────────────────────────────────────────────────────

class _PositionsList extends ConsumerWidget {
  final List<PortfolioPosition> positions;
  final bool isLoading;
  final String currency;
  final bool isOpen;
  final PortfolioTipsData? tips;
  final bool tipsLoading;

  const _PositionsList({
    required this.positions,
    required this.isLoading,
    required this.currency,
    required this.isOpen,
    required this.tips,
    required this.tipsLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && positions.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreen));
    }

    if (positions.isEmpty) {
      return _EmptyState(isOpen: isOpen);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        ...positions.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PositionCard(
                  position: e.value,
                  index: e.key,
                  currency: currency,
                  isOpen: isOpen,
                ),
              ),
            ),
        if (isOpen) ...[
          const SizedBox(height: 8),
          _AiTipsSection(tips: tips, tipsLoading: tipsLoading),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ── Position Card ───────────────────────────────────────────────────────────────

class _PositionCard extends ConsumerWidget {
  final PortfolioPosition position;
  final int index;
  final String currency;
  final bool isOpen;

  const _PositionCard({
    required this.position,
    required this.index,
    required this.currency,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = position;
    final inr = currency == 'INR';
    final sym = currency == 'INR' ? '₹' : '\$';
    final color = colorForSymbol(p.symbol, index);
    final pnl = inr ? (p.live?.unrealizedPnlInr ?? p.realized?.realizedPnlUsd ?? 0) : p.pnlUsd;
    final currentPrice = inr ? (p.live?.currentPriceInr ?? p.live?.currentPrice) : p.live?.currentPrice;
    final posValue = inr ? (p.live?.positionValueInr ?? p.live?.positionValueUsd ?? 0) : (p.live?.positionValueUsd ?? 0);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: p.positive
          ? AppColors.brandGreen.withAlpha(15)
          : AppColors.brandRed.withAlpha(15),
      child: Column(
        children: [
          // Row 1: symbol + direction + leverage | PnL
          Row(
            children: [
              // coin icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withAlpha(25), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    p.symbol.replaceAll('USDT', '').isNotEmpty
                        ? p.symbol.replaceAll('USDT', '')[0]
                        : '?',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.symbol.replaceAll('USDT', ''),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: p.direction.toUpperCase(),
                          color: p.isLong
                              ? AppColors.brandGreen
                              : AppColors.brandRed,
                        ),
                        if (p.leverage > 1) ...[
                          const SizedBox(width: 4),
                          _Badge(
                              label: '${p.leverage}x',
                              color: AppColors.brandBlue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Entry \$${ _fmtPrice(p.entryPrice)} · Qty ${p.quantity}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // PnL
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.positive ? '+' : ''}$sym${_fmtPrice(pnl.abs())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.positive
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  Text(
                    'ROE ${p.roe >= 0 ? '+' : ''}${p.roe.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: p.positive
                          ? AppColors.brandGreen
                          : AppColors.brandRed,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Row 2: live metrics
          if (p.live != null) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _Metric(
                  label: 'Current',
                  value: currentPrice != null
                      ? '$sym${_fmtPrice(currentPrice)}'
                      : '—',
                  color: Colors.white,
                ),
                _Metric(
                  label: 'Value',
                  value: '$sym${_fmtPrice(posValue)}',
                  color: Colors.white,
                ),
                _Metric(
                  label: 'Liq Dist',
                  value: p.live!.liqDistancePct != null
                      ? '${p.live!.liqDistancePct!.toStringAsFixed(1)}%'
                      : 'Spot',
                  color: p.live!.liqDistancePct != null &&
                          p.live!.liqDistancePct! < 10
                      ? AppColors.brandRed
                      : AppColors.textMuted,
                ),
                _Metric(
                  label: 'PnL %',
                  value:
                      '${p.pnlPct >= 0 ? '+' : ''}${p.pnlPct.toStringAsFixed(2)}%',
                  color: p.positive
                      ? AppColors.brandGreen
                      : AppColors.brandRed,
                ),
              ],
            ),
          ],

          // Row 2: closed metrics
          if (p.realized != null) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _Metric(
                    label: 'Exit',
                    value: '\$${_fmtPrice(p.exitPrice ?? 0)}',
                    color: Colors.white),
                _Metric(
                    label: 'PnL %',
                    value:
                        '${p.pnlPct >= 0 ? '+' : ''}${p.pnlPct.toStringAsFixed(2)}%',
                    color: p.positive
                        ? AppColors.brandGreen
                        : AppColors.brandRed),
                _Metric(
                    label: 'ROE',
                    value:
                        '${p.roe >= 0 ? '+' : ''}${p.roe.toStringAsFixed(2)}%',
                    color: p.positive
                        ? AppColors.brandGreen
                        : AppColors.brandRed),
              ],
            ),
          ],

          // Row 3: actions (open positions only)
          if (isOpen) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionBtn(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.textMuted,
                  onTap: () => _confirmDelete(context, ref),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Close Position',
                  icon: Icons.close_rounded,
                  color: AppColors.brandGreen,
                  onTap: () => _showCloseSheet(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Position',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Remove ${position.symbol.replaceAll('USDT', '')} ${position.direction.toUpperCase()} position? This cannot be undone.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(portfolioProvider.notifier).deletePosition(position.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.brandRed)),
          ),
        ],
      ),
    );
  }

  void _showCloseSheet(BuildContext context, WidgetRef ref) {
    final ctrl =
        TextEditingController(text: position.live?.currentPrice?.toStringAsFixed(2) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Close ${position.symbol.replaceAll('USDT', '')} ${position.direction.toUpperCase()}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Entry: \$${_fmtPrice(position.entryPrice)} · Qty: ${position.quantity}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            _InputField(
              label: 'Exit Price (USD)',
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Consumer(builder: (_, r, __) {
              final submitting =
                  r.watch(portfolioProvider.select((s) => s.isSubmitting));
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          final price =
                              double.tryParse(ctrl.text.trim()) ?? 0;
                          if (price <= 0) return;
                          final ok = await r
                              .read(portfolioProvider.notifier)
                              .closePosition(position.id, price);
                          if (ok && context.mounted) Navigator.pop(context);
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Close Position',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _fmtPrice(double v) {
    if (v >= 100000) return v.toStringAsFixed(0);
    if (v >= 1000) return v.toStringAsFixed(1);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }
}

// ── AI Tips Section ─────────────────────────────────────────────────────────────

class _AiTipsSection extends ConsumerWidget {
  final PortfolioTipsData? tips;
  final bool tipsLoading;
  const _AiTipsSection({required this.tips, required this.tipsLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      borderColor: AppColors.brandPurple.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: AppColors.brandPurple, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Portfolio Tips',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('Personalized risk advice from AI',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (tips == null && !tipsLoading)
                GestureDetector(
                  onTap: () =>
                      ref.read(portfolioProvider.notifier).fetchTips(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.brandPurple.withAlpha(60)),
                    ),
                    child: const Text('Analyze',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPurple)),
                  ),
                ),
            ],
          ),
          if (tipsLoading) ...[
            const SizedBox(height: 16),
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.brandPurple)),
            const SizedBox(height: 8),
            const Center(
                child: Text('Analyzing your positions…',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted))),
          ],
          if (tips != null) ...[
            const SizedBox(height: 16),
            // Risk score bar
            Row(
              children: [
                const Text('Risk Score',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tips!.riskScore / 10,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation(
                        tips!.riskScore >= 7
                            ? AppColors.brandRed
                            : tips!.riskScore >= 4
                                ? const Color(0xFFFFAA00)
                                : AppColors.brandGreen,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${tips!.riskScore}/10',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'JetBrainsMono')),
              ],
            ),
            const SizedBox(height: 12),
            // Overall advice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tips!.overallAdvice,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5)),
            ),
            const SizedBox(height: 12),
            // Per-position tips
            ...tips!.positionTips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            color: t.riskColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t.symbol.replaceAll('USDT', ''),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                _Badge(
                                    label: t.risk.toUpperCase(),
                                    color: t.riskColor),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(t.tip,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isOpen;
  const _EmptyState({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen
                  ? Icons.add_chart_rounded
                  : Icons.history_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isOpen ? 'No Open Positions' : 'No Closed Positions',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isOpen
                  ? 'Tap + to add your first trade position and track it live.'
                  : 'Closed positions will appear here once you exit a trade.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Position Sheet ──────────────────────────────────────────────────────────

void _showAddSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddPositionSheet(ref: ref),
  );
}

class _AddPositionSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddPositionSheet({required this.ref});

  @override
  State<_AddPositionSheet> createState() => _AddPositionSheetState();
}

class _AddPositionSheetState extends State<_AddPositionSheet> {
  final _symbol = TextEditingController();
  final _entry = TextEditingController();
  final _qty = TextEditingController();
  final _lev = TextEditingController(text: '1');
  final _liq = TextEditingController();
  final _notes = TextEditingController();
  String _direction = 'long';
  MarketCoin? _selectedCoin;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _symbol.dispose();
    _entry.dispose();
    _qty.dispose();
    _lev.dispose();
    _liq.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _openCoinPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CoinPickerSheet(
        onSelected: (coin) {
          setState(() => _selectedCoin = coin);
          _symbol.text = coin.symbol;
          if (_entry.text.isEmpty) {
            final p = coin.currentPrice;
            _entry.text = p >= 1 ? p.toStringAsFixed(2) : p.toStringAsFixed(6);
          }
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_symbol.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a coin first'),
          backgroundColor: AppColors.brandRed),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final sym = _symbol.text.trim().toUpperCase();
    final body = {
      'symbol': sym.endsWith('USDT') ? sym : '${sym}USDT',
      'direction': _direction,
      'entryPrice': double.parse(_entry.text.trim()),
      'quantity': double.parse(_qty.text.trim()),
      'leverage': int.tryParse(_lev.text.trim()) ?? 1,
      if (_liq.text.trim().isNotEmpty)
        'liquidationPrice': double.parse(_liq.text.trim()),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    };
    final ok =
        await widget.ref.read(portfolioProvider.notifier).addPosition(body);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = widget.ref
        .watch(portfolioProvider.select((s) => s.isSubmitting));

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Position',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 20),

              // Direction toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _direction = 'long'),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _direction == 'long'
                              ? AppColors.brandGreen.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10)),
                          border: Border.all(
                            color: _direction == 'long'
                                ? AppColors.brandGreen
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text('LONG',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _direction == 'long'
                                    ? AppColors.brandGreen
                                    : AppColors.textMuted)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _direction = 'short'),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _direction == 'short'
                              ? AppColors.brandRed.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(10)),
                          border: Border.all(
                            color: _direction == 'short'
                                ? AppColors.brandRed
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text('SHORT',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _direction == 'short'
                                    ? AppColors.brandRed
                                    : AppColors.textMuted)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Symbol picker
              GestureDetector(
                onTap: _openCoinPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      if (_selectedCoin != null) ...[
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7931A).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _selectedCoin!.symbol[0],
                              style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: Color(0xFFF7931A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedCoin!.symbol,
                                style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                              Text(_selectedCoin!.name,
                                style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted,
                                )),
                            ],
                          ),
                        ),
                        Text(_selectedCoin!.formattedPrice,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Colors.white, fontFamily: 'JetBrainsMono',
                          )),
                        const SizedBox(width: 8),
                        const Text('Change', style: TextStyle(
                          fontSize: 10, color: AppColors.brandGreen,
                        )),
                      ] else ...[
                        const Icon(Icons.search_rounded,
                          size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        const Text('Search coin (BTC, ETH, SOL...)',
                          style: TextStyle(
                            fontSize: 13, color: AppColors.textDisabled,
                          )),
                      ],
                    ],
                  ),
                ),
              ),
              if (_selectedCoin == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _symbol.text.isEmpty ? '' : '',
                    style: const TextStyle(fontSize: 10, color: AppColors.brandRed),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: 'Entry Price (USD)',
                      controller: _entry,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      label: 'Quantity',
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: 'Leverage (default 1)',
                      controller: _lev,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      label: 'Liq. Price (optional)',
                      controller: _liq,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InputField(
                label: 'Notes (optional)',
                controller: _notes,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Add Position',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coin Picker Sheet ───────────────────────────────────────────────────────────

class _CoinPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<MarketCoin> onSelected;
  const _CoinPickerSheet({required this.onSelected});

  @override
  ConsumerState<_CoinPickerSheet> createState() => _CoinPickerSheetState();
}

class _CoinPickerSheetState extends ConsumerState<_CoinPickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinsAsync = ref.watch(coinSearchProvider(_query));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search coin by name or symbol...',
                        hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),
          // coin list
          Expanded(
            child: coinsAsync.when(
              loading: () => const Center(
                child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandGreen)),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load coins',
                  style: TextStyle(color: AppColors.brandRed, fontSize: 13)),
              ),
              data: (coins) {
                if (coins.isEmpty) {
                  return const Center(
                    child: Text('No coins found',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: coins.length,
                  itemBuilder: (_, i) {
                    final coin = coins[i];
                    final change = coin.priceChange24h;
                    final positive = change >= 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelected(coin);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.brandGreen.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  coin.symbol[0],
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(coin.symbol,
                                    style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )),
                                  Text(coin.name,
                                    style: const TextStyle(
                                      fontSize: 10, color: AppColors.textMuted,
                                    )),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(coin.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: Colors.white, fontFamily: 'JetBrainsMono',
                                  )),
                                Text(
                                  '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: positive ? AppColors.brandGreen : AppColors.brandRed,
                                    fontFamily: 'JetBrainsMono',
                                  )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ──────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3)),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      validator: validator,
      inputFormatters: keyboardType == TextInputType.number ||
              keyboardType ==
                  const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgPrimary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.borderSubtle)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.brandGreen)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.brandRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.brandRed)),
        isDense: true,
      ),
    );
  }
}
