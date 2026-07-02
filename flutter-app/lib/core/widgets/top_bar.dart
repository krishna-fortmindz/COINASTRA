import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/selected_coin_provider.dart';
import '../../providers/market_memory_provider.dart';
import '../remote/web_socket_baseclass.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          // Live indicator
          _LiveIndicator(),
          const SizedBox(width: 16),

          // Market ticker (desktop)
          if (MediaQuery.of(context).size.width >= 1024) ...[
            _MarketTicker(),
            const Spacer(),
          ] else
            const Spacer(),

          // Search
          _SearchButton(),
          const SizedBox(width: 8),

          // Notifications
          _NotificationButton(),
          const SizedBox(width: 8),

          // Theme toggle
          _ThemeButton(),
        ],
      ),
    );
  }
}

class _LiveIndicator extends ConsumerStatefulWidget {
  const _LiveIndicator({super.key});

  @override
  ConsumerState<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends ConsumerState<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionAsync = ref.watch(socketConnectionProvider);
    final isConnected = connectionAsync.value ?? false;
    final isConnecting = connectionAsync.isLoading;

    final Color indicatorColor;
    final String statusText;

    if (isConnected) {
      indicatorColor = AppColors.brandGreen;
      statusText = 'LIVE';
    } else if (isConnecting) {
      indicatorColor = AppColors.brandAmber;
      statusText = 'CONNECTING';
    } else {
      indicatorColor = AppColors.textDisabled;
      statusText = 'OFFLINE';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor.withValues(alpha: 0.4 + 0.6 * _controller.value),
              boxShadow: [
                BoxShadow(
                  color: indicatorColor.withValues(alpha: 0.3 * _controller.value),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: indicatorColor,
            letterSpacing: 1.2,
            fontFamily: 'JetBrainsMono',
          ),
        ),
      ],
    );
  }
}

class _MarketTicker extends ConsumerWidget {
  const _MarketTicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickersAsync = ref.watch(tickerProvider);
    final tickers = tickersAsync.value ?? const {};

    return Row(
      children: [
        _LiveTickerItem(
          symbol: 'BTCUSDT',
          displayName: 'BTC',
          ticker: tickers['BTCUSDT'],
        ),
        _LiveTickerItem(
          symbol: 'ETHUSDT',
          displayName: 'ETH',
          ticker: tickers['ETHUSDT'],
        ),
        _LiveTickerItem(
          symbol: 'SOLUSDT',
          displayName: 'SOL',
          ticker: tickers['SOLUSDT'],
        ),
        _LiveTickerItem(
          symbol: 'BNBUSDT',
          displayName: 'BNB',
          ticker: tickers['BNBUSDT'],
        ),
      ],
    );
  }
}

class _LiveTickerItem extends StatefulWidget {
  final String symbol;
  final String displayName;
  final TickerUpdate? ticker;

  const _LiveTickerItem({
    super.key,
    required this.symbol,
    required this.displayName,
    required this.ticker,
  });

  @override
  State<_LiveTickerItem> createState() => _LiveTickerItemState();
}

class _LiveTickerItemState extends State<_LiveTickerItem> {
  Color _textColor = Colors.white;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _LiveTickerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentPrice = widget.ticker?.close;
    final oldPrice = oldWidget.ticker?.close;

    if (currentPrice != null && oldPrice != null && currentPrice != oldPrice) {
      _timer?.cancel();
      setState(() {
        _textColor = currentPrice > oldPrice ? AppColors.brandGreen : AppColors.brandRed;
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
    final priceStr = widget.ticker != null
        ? '\$${widget.ticker!.close.toStringAsFixed(widget.ticker!.close < 10 ? 3 : 2)}'
        : '---';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.displayName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(width: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textColor,
              fontFamily: 'JetBrainsMono',
            ),
            child: Text(priceStr),
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TopBarButton(
      icon: Icons.search_rounded,
      onTap: () => _showSearchOverlay(context),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'search',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) =>
          _SearchDialog(currentLocation: currentLocation),
    );
  }
}

class _SearchDialog extends ConsumerStatefulWidget {
  final String currentLocation;
  const _SearchDialog({super.key, required this.currentLocation});

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  final _controller = TextEditingController();
  String _query = '';

  static const _featuredSymbols = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'DOGE'];

  static const _screens = [
    _SearchItem('Dashboard', 'Market overview & live data', '/dashboard', Icons.dashboard_rounded, AppColors.brandGreen),
    _SearchItem('Trade Now', 'AI trading signal aggregator', '/trade-now', Icons.bolt_rounded, AppColors.brandGreen),
    _SearchItem('AI Analysis', 'Deep AI coin analysis', '/analysis', Icons.psychology_rounded, AppColors.brandPurple),
    _SearchItem('Charts', 'Candlestick & technical analysis', '/charts', Icons.candlestick_chart_rounded, AppColors.brandBlue),
    _SearchItem('News', 'Market news & coin signals', '/sentiment', Icons.newspaper_rounded, AppColors.brandAmber),
    _SearchItem('New Listings', 'New coin listings & AI scoring', '/listings', Icons.new_releases_rounded, AppColors.brandGreen),
    _SearchItem('Order Book', 'Bid/ask walls & depth', '/orderbook', Icons.menu_rounded, AppColors.brandBlue),
    _SearchItem('Token Unlocks', 'Vesting schedule & risk', '/token-unlocks', Icons.lock_open_rounded, AppColors.brandAmber),
    _SearchItem('Portfolio', 'Holdings & P&L tracker', '/portfolio', Icons.pie_chart_rounded, AppColors.brandPurple),
    _SearchItem('Risk Manager', 'Position sizing & risk tools', '/risk', Icons.shield_rounded, AppColors.brandRed),
    _SearchItem('Trade Journal', 'Log & review your trades', '/journal', Icons.book_rounded, AppColors.brandBlue),
    _SearchItem('AI Chat', 'Chat with AI copilot', '/chat', Icons.chat_bubble_outline_rounded, AppColors.brandGreen),
    _SearchItem('Profile', 'Settings & account', '/profile', Icons.person_rounded, AppColors.textMuted),
  ];

  List<_SearchItem> get _filteredScreens {
    if (_query.isEmpty) return _screens.take(4).toList();
    final q = _query.toLowerCase();
    return _screens
        .where((s) => s.title.toLowerCase().contains(q) || s.subtitle.toLowerCase().contains(q))
        .toList();
  }

  void _goToCoin(String symbol) {
    Navigator.of(context).pop();
    final upper = symbol.toUpperCase();
    ref.read(selectedCoinProvider.notifier).state = upper;

    // Coin-specific screens: stay on current screen, they sync via selectedCoinProvider
    const coinScreens = {'/memory', '/analysis', '/charts', '/orderbook'};
    if (coinScreens.contains(widget.currentLocation)) {
      if (widget.currentLocation == '/memory') {
        ref.read(memorySymbolProvider.notifier).state = upper;
      }
      context.go(widget.currentLocation);
    } else {
      context.go('/trade-now');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickers = ref.watch(tickerProvider).value ?? const {};
    final filteredScreens = _filteredScreens;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.08,
          left: 20, right: 20,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Search input ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 15, color: Colors.white),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Search any coin or navigate...',
                            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 15),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ESC', style: TextStyle(
                            fontSize: 10, color: AppColors.textMuted, fontFamily: 'JetBrainsMono',
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      // ── Coins ──
                      const _SectionHeader('COINS'),
                      if (_query.length >= 2)
                        _ApiCoinSection(query: _query, onTap: _goToCoin)
                      else
                        ..._featuredSymbols.map((sym) {
                          final ticker = tickers['${sym}USDT'];
                          final priceStr = ticker != null
                              ? '\$${ticker.close.toStringAsFixed(ticker.close < 10 ? 3 : 2)}'
                              : '—';
                          return _CoinResultRow(
                            symbol: sym,
                            subtitle: priceStr,
                            onTap: () => _goToCoin(sym),
                          );
                        }),

                      // ── Screens ──
                      if (filteredScreens.isNotEmpty) ...[
                        const _SectionHeader('SCREENS'),
                        ...filteredScreens.map((item) => _SearchResultRow(
                          item: item,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(item.route);
                          },
                        )),
                      ],

                      if (_query.isNotEmpty && filteredScreens.isEmpty && _query.length < 2)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No results', style: TextStyle(
                              fontSize: 14, color: AppColors.textMuted)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(label, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.textDisabled, letterSpacing: 1.0,
      )),
    );
  }
}

class _SearchItem {
  final String title, subtitle, route;
  final IconData icon;
  final Color color;
  const _SearchItem(this.title, this.subtitle, this.route, this.icon, this.color);
}

class _SearchResultRow extends StatelessWidget {
  final _SearchItem item;
  final VoidCallback onTap;
  const _SearchResultRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
                  _SearchResultSubtitle(item: item),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _SearchResultSubtitle extends ConsumerStatefulWidget {
  final _SearchItem item;
  const _SearchResultSubtitle({super.key, required this.item});

  @override
  ConsumerState<_SearchResultSubtitle> createState() => _SearchResultSubtitleState();
}

class _SearchResultSubtitleState extends ConsumerState<_SearchResultSubtitle> {
  Color _textColor = AppColors.textMuted;
  Timer? _timer;
  double? _prevPrice;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCoin = widget.item.route == '/analysis';
    if (!isCoin) {
      return Text(
        widget.item.subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textMuted,
        ),
      );
    }

    final symbol = '${widget.item.title}USDT';
    final tickersAsync = ref.watch(tickerProvider);
    final tickers = tickersAsync.value ?? const {};
    final ticker = tickers[symbol];

    if (ticker != null) {
      final currentPrice = ticker.close;
      if (_prevPrice != null && _prevPrice != currentPrice) {
        _timer?.cancel();
        setState(() {
          _textColor = currentPrice > _prevPrice! ? AppColors.brandGreen : AppColors.brandRed;
        });
        _timer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _textColor = AppColors.textMuted;
            });
          }
        });
      }
      _prevPrice = currentPrice;

      // Extract original coin name from subtitle before the middle dot
      final parts = widget.item.subtitle.split(' · ');
      final name = parts.isNotEmpty ? parts.first : widget.item.title;
      final priceStr = '\$${currentPrice.toStringAsFixed(currentPrice < 10 ? 3 : 2)}';

      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontSize: 11,
          color: _textColor,
          fontFamily: _textColor != AppColors.textMuted ? 'JetBrainsMono' : null,
          fontWeight: _textColor != AppColors.textMuted ? FontWeight.w700 : null,
        ),
        child: Text('$name · $priceStr'),
      );
    }

    return Text(
      widget.item.subtitle,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ── API coin search section ────────────────────────────────────────────────────

class _ApiCoinSection extends ConsumerWidget {
  final String query;
  final void Function(String symbol) onTap;
  const _ApiCoinSection({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coinSearchProvider(query));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(color: AppColors.brandGreen, strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text('Could not load coins', style: TextStyle(fontSize: 12, color: AppColors.brandRed)),
      ),
      data: (coins) {
        if (coins.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('No coins found', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          );
        }
        return Column(
          children: coins.take(8).map((coin) => _CoinResultRow(
            symbol: coin.symbol,
            subtitle: '${coin.name}  ${coin.formattedChange}',
            changePositive: coin.positive,
            onTap: () => onTap(coin.symbol),
          )).toList(),
        );
      },
    );
  }
}

class _CoinResultRow extends StatelessWidget {
  final String symbol;
  final String subtitle;
  final bool? changePositive;
  final VoidCallback onTap;

  const _CoinResultRow({
    required this.symbol,
    required this.subtitle,
    this.changePositive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor = changePositive == null
        ? AppColors.textMuted
        : changePositive!
            ? AppColors.brandGreen
            : AppColors.brandRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  symbol.isNotEmpty ? symbol[0] : '?',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: subtitleColor)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ── Notification button ───────────────────────────────────────────────────────

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TopBarButton(
      icon: Icons.notifications_outlined,
      onTap: () {},
    );
  }
}

class _ThemeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TopBarButton(
      icon: Icons.wb_sunny_outlined,
      onTap: () {},
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, size: 17, color: AppColors.textMuted),
      ),
    );
  }
}