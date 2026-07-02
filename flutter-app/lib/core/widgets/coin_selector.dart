import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../remote/data/dashboard/models/dashboard_models.dart';

class CoinMeta {
  final String symbol, name, price, change;
  final bool positive;
  final Color color;
  const CoinMeta({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.positive,
    required this.color,
  });
}

const kAllCoins = [
  CoinMeta(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: '\$97,420',
      change: '+2.4%',
      positive: true,
      color: Color(0xFFF7931A)),
  CoinMeta(
      symbol: 'ETH',
      name: 'Ethereum',
      price: '\$3,842',
      change: '+1.8%',
      positive: true,
      color: Color(0xFF627EEA)),
  CoinMeta(
      symbol: 'SOL',
      name: 'Solana',
      price: '\$184',
      change: '-0.9%',
      positive: false,
      color: Color(0xFF9945FF)),
  CoinMeta(
      symbol: 'BNB',
      name: 'BNB',
      price: '\$612',
      change: '+3.1%',
      positive: true,
      color: Color(0xFFF3BA2F)),
  CoinMeta(
      symbol: 'XRP',
      name: 'Ripple',
      price: '\$2.14',
      change: '+5.2%',
      positive: true,
      color: Color(0xFF0085C3)),
  CoinMeta(
      symbol: 'DOGE',
      name: 'Dogecoin',
      price: '\$0.182',
      change: '+12.4%',
      positive: true,
      color: Color(0xFFC2A633)),
  CoinMeta(
      symbol: 'ADA',
      name: 'Cardano',
      price: '\$0.68',
      change: '-1.2%',
      positive: false,
      color: Color(0xFF0033AD)),
  CoinMeta(
      symbol: 'AVAX',
      name: 'Avalanche',
      price: '\$38.4',
      change: '+4.7%',
      positive: true,
      color: Color(0xFFE84142)),
  CoinMeta(
      symbol: 'DOT',
      name: 'Polkadot',
      price: '\$9.12',
      change: '-0.4%',
      positive: false,
      color: Color(0xFFE6007A)),
  CoinMeta(
      symbol: 'LINK',
      name: 'Chainlink',
      price: '\$18.72',
      change: '+2.1%',
      positive: true,
      color: Color(0xFF375BD2)),
  CoinMeta(
      symbol: 'MATIC',
      name: 'Polygon',
      price: '\$0.94',
      change: '-2.8%',
      positive: false,
      color: Color(0xFF8247E5)),
  CoinMeta(
      symbol: 'UNI',
      name: 'Uniswap',
      price: '\$11.40',
      change: '+1.5%',
      positive: true,
      color: Color(0xFFFF007A)),
  CoinMeta(
      symbol: 'ATOM',
      name: 'Cosmos',
      price: '\$8.84',
      change: '+0.8%',
      positive: true,
      color: Color(0xFF2E3148)),
  CoinMeta(
      symbol: 'LTC',
      name: 'Litecoin',
      price: '\$92.40',
      change: '+1.1%',
      positive: true,
      color: Color(0xFF345D9D)),
  CoinMeta(
      symbol: 'NEAR',
      name: 'NEAR',
      price: '\$6.48',
      change: '+3.4%',
      positive: true,
      color: Color(0xFF00C08B)),
  CoinMeta(
      symbol: 'APT',
      name: 'Aptos',
      price: '\$7.92',
      change: '-3.1%',
      positive: false,
      color: Color(0xFF2DD8A3)),
  CoinMeta(
      symbol: 'ARB',
      name: 'Arbitrum',
      price: '\$1.31',
      change: '-1.8%',
      positive: false,
      color: Color(0xFF12AAFF)),
  CoinMeta(
      symbol: 'OP',
      name: 'Optimism',
      price: '\$2.08',
      change: '+0.6%',
      positive: true,
      color: Color(0xFFFF0420)),
  CoinMeta(
      symbol: 'SUI',
      name: 'Sui',
      price: '\$1.84',
      change: '+7.2%',
      positive: true,
      color: Color(0xFF4DA2FF)),
  CoinMeta(
      symbol: 'TON',
      name: 'Toncoin',
      price: '\$5.62',
      change: '+2.9%',
      positive: true,
      color: Color(0xFF0088CC)),
];

CoinMeta coinBySymbol(String symbol) => kAllCoins.firstWhere(
      (c) => c.symbol.toUpperCase() == symbol.toUpperCase(),
      orElse: () => kAllCoins.first,
    );

Color _colorForSymbol(String symbol) {
  const colorMap = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'BNB': Color(0xFFF3BA2F),
    'XRP': Color(0xFF0085C3),
    'DOGE': Color(0xFFC2A633),
    'ADA': Color(0xFF0033AD),
    'AVAX': Color(0xFFE84142),
    'DOT': Color(0xFFE6007A),
    'LINK': Color(0xFF375BD2),
    'MATIC': Color(0xFF8247E5),
    'UNI': Color(0xFFFF007A),
    'ATOM': Color(0xFF2E3148),
    'LTC': Color(0xFF345D9D),
    'NEAR': Color(0xFF00C08B),
    'APT': Color(0xFF2DD8A3),
    'ARB': Color(0xFF12AAFF),
    'OP': Color(0xFFFF0420),
    'SUI': Color(0xFF4DA2FF),
    'TON': Color(0xFF0088CC),
  };
  return colorMap[symbol] ?? const Color(0xFF999999);
}

// ── Reusable coin avatar ──────────────────────────────────────
Widget _coinAvatar(String symbol, {double size = 30}) {
  final color = _colorForSymbol(symbol);
  return Container(
    width: size,
    height: size,
    decoration:
        BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
    child: Center(
      child: Text(
        symbol[0],
        style: TextStyle(
            fontSize: size * 0.43, fontWeight: FontWeight.w800, color: color),
      ),
    ),
  );
}

// ── Change badge ──────────────────────────────────────────────
Widget _changeBadge(String text, bool positive) {
  final color = positive ? AppColors.brandGreen : AppColors.brandRed;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: 'JetBrainsMono',
      ),
    ),
  );
}

/// Drop-in coin selector bar for any screen.
class CoinSelector extends ConsumerWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const CoinSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show correct static coin immediately — no "Loading..." flicker
    final staticCoin = coinBySymbol(selected);
    final coinsAsync = ref.watch(coinSearchProvider(selected));

    Widget staticRow() => _SelectorRow(
          symbol: staticCoin.symbol,
          name: staticCoin.name,
          priceWidget: Text(
            staticCoin.price,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          changeWidget: _changeBadge(staticCoin.change, staticCoin.positive),
        );

    return GestureDetector(
      onTap: () => _openSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: coinsAsync.when(
          // Show static data immediately — selector looks correct the moment coin changes
          loading: () => staticRow(),
          error: (_, __) => staticRow(),
          data: (coins) {
            // Find exact symbol match; if not found fall back to static (never wrong coin)
            final mc = coins.cast<MarketCoin?>().firstWhere(
                  (c) => c!.symbol.toUpperCase() == selected.toUpperCase(),
                  orElse: () => null,
                );
            if (mc == null) return staticRow();

            final changeStr =
                '${mc.priceChange24h >= 0 ? '+' : ''}${mc.priceChange24h.toStringAsFixed(2)}%';
            return _SelectorRow(
              symbol: mc.symbol,
              name: mc.name,
              priceWidget: Text(
                mc.formattedPrice,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              changeWidget: _changeBadge(changeStr, mc.priceChange24h >= 0),
            );
          },
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'coin-search',
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
      pageBuilder: (ctx, _, __) => _CoinSearchDialog(
        selected: selected,
        onSelected: (s) {
          Navigator.of(ctx).pop();
          onChanged(s);
        },
      ),
    );
  }
}

// ── Shared selector row layout — NO Spacer, uses Expanded properly ────────────
class _SelectorRow extends StatelessWidget {
  final String symbol;
  final String name;
  final Widget priceWidget;
  final Widget changeWidget;

  const _SelectorRow({
    required this.symbol,
    required this.name,
    required this.priceWidget,
    required this.changeWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _coinAvatar(symbol),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(width: 12),
        priceWidget,
        const SizedBox(width: 8),
        changeWidget,
        const SizedBox(width: 10),
        const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted, size: 18),
      ],
    );
  }
}

// ── Search dialog ─────────────────────────────────────────────
class _CoinSearchDialog extends ConsumerStatefulWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _CoinSearchDialog({required this.selected, required this.onSelected});

  @override
  ConsumerState<_CoinSearchDialog> createState() => _CoinSearchDialogState();
}

class _CoinSearchDialogState extends ConsumerState<_CoinSearchDialog> {
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
                // ── Search field ──────────────────────────────
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
                                fontFamily: 'JetBrainsMono',
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1),

                // ── Coin list ─────────────────────────────────
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                              final isSelected = coin.symbol == widget.selected;
                              final color = _colorForSymbol(coin.symbol);
                              final change = coin.priceChange24h;
                              final changeStr =
                                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';

                              return GestureDetector(
                                onTap: () => widget.onSelected(coin.symbol),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  color: isSelected
                                      ? AppColors.brandGreen.withAlpha(8)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            coin.symbol[0],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Name + symbol — Expanded takes slack
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(coin.symbol,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                )),
                                            Text(coin.name,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                )),
                                          ],
                                        ),
                                      ),

                                      // Price — fixed width prevents overflow
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
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Change — fixed width
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          changeStr,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: change >= 0
                                                ? AppColors.brandGreen
                                                : AppColors.brandRed,
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                        ),
                                      ),

                                      // Checkmark — only when selected
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.brandGreen),
                                      ] else
                                        // Keep row height consistent
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
