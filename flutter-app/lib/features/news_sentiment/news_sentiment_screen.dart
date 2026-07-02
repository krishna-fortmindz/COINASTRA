import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/remote/data/sentiment/sentiment_models.dart';
import '../../providers/sentiment_provider.dart';
import '../../providers/dashboard_provider.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class NewsSentimentScreen extends ConsumerStatefulWidget {
  const NewsSentimentScreen({super.key});

  @override
  ConsumerState<NewsSentimentScreen> createState() =>
      _NewsSentimentScreenState();
}

class _NewsSentimentScreenState extends ConsumerState<NewsSentimentScreen>
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _Header(tabController: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _NewsTab(),
                _CoinSignalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TabController tabController;
  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('News',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Text('Real-time market news aggregation',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.brandGreen,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            indicatorColor: AppColors.brandGreen,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'News'),
              Tab(text: 'Coin Signals'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── News Tab ──────────────────────────────────────────────────────────────────

class _NewsTab extends ConsumerWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sentimentNewsProvider);

    if (state.isLoading && state.items.isEmpty) return const _LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(sentimentNewsProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const _EmptyView(message: 'No news available');
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                color: AppColors.brandGreen,
                backgroundColor: AppColors.bgSecondary,
                onRefresh: () =>
                    ref.read(sentimentNewsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NewsCard(item: state.items[i]),
                ),
              ),
              if (state.isLoading)
                Container(
                  color: AppColors.bgPrimary.withOpacity(0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandGreen,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _PaginationBar(
          page: state.page,
          totalPages: state.totalPages,
          hasNext: state.hasNextPage,
          hasPrevious: state.hasPreviousPage,
          isLoading: state.isLoading,
          onNext: () => ref.read(sentimentNewsProvider.notifier).nextPage(),
          onPrevious: () =>
              ref.read(sentimentNewsProvider.notifier).previousPage(),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final SentimentNewsItem item;
  const _NewsCard({required this.item});

  Color _sentimentColor(String s) {
    switch (s.toLowerCase()) {
      case 'bullish':
        return AppColors.brandGreen;
      case 'bearish':
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
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _sentimentColor(item.sentiment);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _SentimentBadge(label: item.sentiment, color: color),
                      if (item.sentimentScore != null)
                        Text(
                          '${(item.sentimentScore! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontFamily: 'JetBrainsMono'),
                        ),
                      Text(
                        item.source,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                      Text(
                        _timeAgo(item.publishedAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textDisabled),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            const SizedBox(width: 10),
            _NewsImage(url: item.imageUrl!),
          ],
        ],
      ),
    );
  }
}

// ── News image (HtmlElementView bypasses CanvasKit CORS) ─────────────────────

class _NewsImage extends StatefulWidget {
  final String url;
  const _NewsImage({required this.url});

  @override
  State<_NewsImage> createState() => _NewsImageState();
}

class _NewsImageState extends State<_NewsImage> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    // Unique viewId per instance so re-registering is safe
    _viewId = 'ni${widget.url.hashCode.abs()}x${identityHashCode(this)}';
    try {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) {
        return html.ImageElement()
          ..src = widget.url
          ..style.cssText =
              'width:68px;height:68px;object-fit:cover;'
              'border-radius:8px;display:block;';
      });
    } catch (_) {
      // Already registered — safe to ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}

// ── Pagination bar ────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int page;
  final int? totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _PaginationBar({
    required this.page,
    this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.isLoading,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          _PageButton(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            iconLeading: true,
            enabled: hasPrevious && !isLoading,
            onTap: onPrevious,
          ),
          const Spacer(),
          Text(
            totalPages != null ? 'Page $page of $totalPages' : 'Page $page',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          _PageButton(
            label: 'Next',
            icon: Icons.chevron_right_rounded,
            iconLeading: false,
            enabled: hasNext && !isLoading,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconLeading;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.label,
    required this.icon,
    required this.iconLeading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : AppColors.textMuted;
    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppColors.borderSubtle
                : AppColors.borderSubtle.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconLeading ? children : children.reversed.toList(),
        ),
      ),
    );
  }
}
// ── Coin Signals Tab ──────────────────────────────────────────────────────────

class _CoinSignalsTab extends ConsumerWidget {
  const _CoinSignalsTab();

  void _openPicker(BuildContext context, WidgetRef ref, String selectedId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'coin-picker',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, -0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => _CoinPickerDialog(
        selectedId: selectedId,
        onSelected: (id) {
          Navigator.of(ctx).pop();
          ref.read(sentimentCoinIdProvider.notifier).state = id;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(sentimentCoinIdProvider);
    final data = ref.watch(coinSentimentProvider(selectedId));

    return Column(
      children: [
        // Coin search / picker
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: GestureDetector(
            onTap: () => _openPicker(context, ref, selectedId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search coin by name or symbol...',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedId.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: data.when(
            loading: () => const _LoadingView(),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(coinSentimentProvider(selectedId)),
            ),
            data: (d) => RefreshIndicator(
              color: AppColors.brandGreen,
              backgroundColor: AppColors.bgSecondary,
              onRefresh: () async =>
                  ref.invalidate(coinSentimentProvider(selectedId)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _CoinOverallCard(data: d),
                  if (d.signals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signal Breakdown',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 14),
                          ...d.signals.map((s) => _SignalRow(signal: s)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Coin Picker Dialog ────────────────────────────────────────────────────────

class _CoinPickerDialog extends ConsumerStatefulWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  const _CoinPickerDialog({required this.selectedId, required this.onSelected});

  @override
  ConsumerState<_CoinPickerDialog> createState() => _CoinPickerDialogState();
}

class _CoinPickerDialogState extends ConsumerState<_CoinPickerDialog> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.06,
          left: 16,
          right: 16,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Search coin by name or symbol...',
                            hintStyle: TextStyle(
                                color: AppColors.textDisabled, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('ESC',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                  fontFamily: 'JetBrainsMono')),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1),
                // Coin list
                Flexible(
                  child: Consumer(
                    builder: (ctx, ref, _) {
                      final coinsAsync = ref.watch(coinSearchProvider(_query));
                      return coinsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.brandGreen),
                          ),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Error loading coins',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.brandRed)),
                        ),
                        data: (coins) {
                          if (coins.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No coins found',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted)),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: coins.length,
                            itemBuilder: (_, i) {
                              final coin = coins[i];
                              final isSelected = coin.id == widget.selectedId;
                              return GestureDetector(
                                onTap: () => widget.onSelected(coin.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  color: isSelected
                                      ? AppColors.brandGreen.withAlpha(8)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      _CoinAvatar(
                                          symbol: coin.symbol,
                                          imageUrl: coin.imageUrl),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(coin.symbol,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
                                            Text(coin.name,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          coin.formattedPrice,
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontFamily: 'JetBrainsMono'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${coin.priceChange24h >= 0 ? '+' : ''}${coin.priceChange24h.toStringAsFixed(2)}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: coin.priceChange24h >= 0
                                                  ? AppColors.brandGreen
                                                  : AppColors.brandRed,
                                              fontFamily: 'JetBrainsMono'),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.brandGreen),
                                      ] else
                                        const SizedBox(width: 22),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  final String symbol;
  final String? imageUrl;
  const _CoinAvatar({required this.symbol, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final colors = [
      AppColors.brandGreen,
      AppColors.brandBlue,
      AppColors.brandAmber,
      AppColors.brandPurple,
      AppColors.brandRed,
    ];
    final color = colors[symbol.codeUnitAt(0) % colors.length];
    return Container(
      width: 34,
      height: 34,
      decoration:
          BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
      child: Center(
        child: Text(
          symbol.isNotEmpty ? symbol[0] : '?',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}

class _CoinOverallCard extends StatelessWidget {
  final CoinSentimentData data;
  const _CoinOverallCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sentiment = data.overallSentiment.toLowerCase();
    final color = sentiment == 'bullish'
        ? AppColors.brandGreen
        : sentiment == 'bearish'
            ? AppColors.brandRed
            : AppColors.brandAmber;

    return GlassCard(
      borderColor: color.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.symbol.isNotEmpty
                          ? '${data.symbol}/USDT'
                          : data.coinId,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('Overall Sentiment',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.overallScore.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFamily: 'JetBrainsMono'),
                  ),
                  _SentimentBadge(label: data.overallSentiment, color: color),
                ],
              ),
            ],
          ),
          if (data.aiSummary != null && data.aiSummary!.isNotEmpty) ...[
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
                    color: AppColors.brandAmber.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      size: 13, color: AppColors.brandAmber),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(data.aiSummary!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  final CoinSignal signal;
  const _SignalRow({required this.signal});

  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'bullish':
        return AppColors.brandGreen;
      case 'bearish':
        return AppColors.brandRed;
      default:
        return AppColors.brandAmber;
    }
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'social':
        return Icons.people_rounded;
      case 'onchain':
      case 'on-chain':
      case 'on_chain':
        return Icons.account_tree_rounded;
      case 'news':
        return Icons.article_rounded;
      case 'technical':
        return Icons.candlestick_chart_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(signal.signal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(signal.type), size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_capitalize(signal.type),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const Spacer(),
                    if (signal.confidence != null)
                      Text('${signal.confidence!.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontFamily: 'JetBrainsMono')),
                    const SizedBox(width: 6),
                    _SentimentBadge(label: signal.signal, color: color),
                  ],
                ),
                if (signal.description != null) ...[
                  const SizedBox(height: 3),
                  Text(signal.description!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SentimentBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SentimentBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
          color: AppColors.brandGreen, strokeWidth: 2),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.brandGreen)),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
    );
  }
}
