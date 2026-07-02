import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/coin_selector.dart';
import '../../core/remote/data/orderbook/models/orderbook_models.dart';
import '../../core/remote/web_socket_baseclass.dart';
import '../../providers/ai_analysis_provider.dart';
import '../../providers/charts_provider.dart';
import '../../providers/orderbook_provider.dart';
import '../../providers/selected_coin_provider.dart';

class OrderbookScreen extends ConsumerStatefulWidget {
  const OrderbookScreen({super.key});

  @override
  ConsumerState<OrderbookScreen> createState() => _OrderbookScreenState();
}

class _OrderbookScreenState extends ConsumerState<OrderbookScreen> {
  String get _selectedCoin => ref.watch(selectedCoinProvider);

  @override
  Widget build(BuildContext context) {
    final obState = ref.watch(orderBookProvider);

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
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCoinSelector(),
                  const SizedBox(height: 20),
                  _buildSpreadInfo(obState.ticker, obState.orderBook),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (_, c) {
                    if (c.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderbook(obState),
                          const SizedBox(height: 16),
                          _buildDepthVisual(obState.orderBook),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildOrderbook(obState)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDepthVisual(obState.orderBook)),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildKeyLevels(obState),
                  const SizedBox(height: 16),
                  if (obState.recentTrades.isNotEmpty)
                    _buildRecentTrades(obState.recentTrades),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Book',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Bid/ask walls · Depth · Key support & resistance',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        NeonBadge(label: 'LIVE', color: AppColors.brandGreen, icon: Icons.circle),
      ],
    );
  }

  Widget _buildCoinSelector() {
    return CoinSelector(
      selected: _selectedCoin,
      onChanged: (c) {
        ref.read(selectedCoinProvider.notifier).state = c;
        ref.read(aiAnalysisProvider).selectCoin(c);
        ref.read(chartsProvider).setCoin(c);
        ref.read(orderBookProvider.notifier).selectCoin(c);
      },
    );
  }

  Widget _buildSpreadInfo(AsyncValue<Ticker24hrData> tickerAsync, AsyncValue<OrderBookData> obAsync) {
    final t = tickerAsync.valueOrNull ?? Ticker24hrData.empty;
    final ob = obAsync.valueOrNull;
    final isLoading = tickerAsync.isLoading && ob == null;

    // Derive best bid/ask from order book when ticker doesn't include them
    final double bestBidPrice = t.bestBid > 0
        ? t.bestBid
        : (ob != null && ob.bids.isNotEmpty ? ob.bids.first.price : 0);
    final double bestAskPrice = t.bestAsk > 0
        ? t.bestAsk
        : (ob != null && ob.asks.isNotEmpty ? ob.asks.first.price : 0);

    final double spreadVal =
        (bestBidPrice > 0 && bestAskPrice > 0) ? bestAskPrice - bestBidPrice : 0;
    final double lastPrice = t.lastPrice > 0 ? t.lastPrice : bestBidPrice;
    final spreadStr = spreadVal > 0
        ? '\$${spreadVal.toStringAsFixed(2)} (${(spreadVal / lastPrice * 100).toStringAsFixed(3)}%)'
        : '—';

    return Row(
      children: [
        _SpreadTile(isLoading ? '—' : t.formattedLast, 'Last Price', Colors.white),
        const SizedBox(width: 12),
        _SpreadTile(isLoading ? '—' : (bestBidPrice > 0 ? _formatPrice(bestBidPrice) : '—'), 'Best Bid', AppColors.brandGreen),
        const SizedBox(width: 12),
        _SpreadTile(isLoading ? '—' : (bestAskPrice > 0 ? _formatPrice(bestAskPrice) : '—'), 'Best Ask', AppColors.brandRed),
        const SizedBox(width: 12),
        _SpreadTile(isLoading ? '—' : spreadStr, 'Spread', AppColors.brandAmber),
      ],
    );
  }

  Widget _buildOrderbook(OrderBookState obState) {
    return obState.orderBook.when(
      loading: () => GlassCard(
        padding: const EdgeInsets.all(0),
        child: const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.brandGreen,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (e, _) => GlassCard(
        child: Center(
          child: Text(
            'Failed to load order book',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ),
      data: (ob) {
        final bids = ob.bidsWithTotal;
        final asks = ob.asksWithTotal;
        final maxTotal = math.max(
          bids.isEmpty ? 0.0 : bids.last.total,
          asks.isEmpty ? 0.0 : asks.last.total,
        );
        final ticker = obState.ticker.valueOrNull ?? Ticker24hrData.empty;

        return GlassCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Price (USDT)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Size',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderSubtle, height: 1),
              ...asks.reversed
                  .toList()
                  .map((a) => _OrderRow(level: a, maxTotal: maxTotal)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: AppColors.bgTertiary,
                child: Row(
                  children: [
                    const Icon(Icons.horizontal_rule_rounded,
                        size: 14, color: AppColors.textDisabled),
                    const SizedBox(width: 6),
                    Text(
                      ticker.lastPrice > 0
                          ? '${ticker.formattedLast} · Spread ${ticker.spreadFormatted}'
                          : 'Loading…',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                ),
              ),
              ...bids.map((b) => _OrderRow(level: b, maxTotal: maxTotal)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepthVisual(AsyncValue<OrderBookData> orderBook) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cumulative Depth',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _LegendDot(AppColors.brandGreen, 'Bids'),
              const SizedBox(width: 12),
              _LegendDot(AppColors.brandRed, 'Asks'),
            ],
          ),
          const SizedBox(height: 20),
          orderBook.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.brandGreen, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 60,
              child: Center(
                child: Text('Unable to load depth',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ),
            ),
            data: (ob) {
              final asks = ob.asksWithTotal;
              final bids = ob.bidsWithTotal;
              final maxAsk =
                  asks.isEmpty ? 1.0 : asks.last.total;
              final maxBid =
                  bids.isEmpty ? 1.0 : bids.last.total;

              return Column(
                children: [
                  ...asks.reversed.take(8).map((a) {
                    final pct = a.total / maxAsk;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '\$${a.price.toStringAsFixed(a.price >= 100 ? 0 : 2)}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.brandRed,
                                  fontFamily: 'JetBrainsMono'),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor:
                                    AppColors.brandRed.withAlpha(10),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.brandRed),
                                minHeight: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      height: 1,
                      color: AppColors.brandAmber.withAlpha(60),
                    ),
                  ),
                  ...bids.take(8).map((b) {
                    final pct = b.total / maxBid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '\$${b.price.toStringAsFixed(b.price >= 100 ? 0 : 2)}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.brandGreen,
                                  fontFamily: 'JetBrainsMono'),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor:
                                    AppColors.brandGreen.withAlpha(10),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.brandGreen),
                                minHeight: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyLevels(OrderBookState obState) {
    return obState.keyLevels.when(
      loading: () => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Price Levels',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.brandGreen, strokeWidth: 2),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (levels) {
        if (levels.isEmpty) return const SizedBox.shrink();
        final ticker = obState.ticker.valueOrNull ?? Ticker24hrData.empty;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Key Price Levels',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 14),
              if (ticker.lastPrice > 0)
                _KeyLevelRow(
                  price: _formatPrice(ticker.lastPrice),
                  label: 'Current Price',
                  note: 'Last traded',
                  color: Colors.white,
                  icon: Icons.circle,
                ),
              ...levels.map((l) {
                final color = l.isCurrent
                    ? Colors.white
                    : l.isSupport
                        ? AppColors.brandGreen
                        : AppColors.brandRed;
                final icon = l.isCurrent
                    ? Icons.circle
                    : l.isSupport
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded;
                return _KeyLevelRow(
                  price: _formatPrice(l.price),
                  label: l.label,
                  note: l.note,
                  color: color,
                  icon: icon,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTrades(List<MarketTradeUpdate> trades) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Trades',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LIVE',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                child: Text('Price',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text('Qty',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text('Time',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...trades.take(15).map((t) {
            final color = t.isBuy ? AppColors.brandGreen : AppColors.brandRed;
            final h = t.time.hour.toString().padLeft(2, '0');
            final m = t.time.minute.toString().padLeft(2, '0');
            final s = t.time.second.toString().padLeft(2, '0');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.formattedPrice,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      t.formattedQty,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontFamily: 'JetBrainsMono'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$h:$m:$s',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          fontFamily: 'JetBrainsMono'),
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

  static String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }
}

// ── Key Level Row ──────────────────────────────────────────────────────────────

class _KeyLevelRow extends StatelessWidget {
  final String price, label, note;
  final Color color;
  final IconData icon;

  const _KeyLevelRow({
    required this.price,
    required this.label,
    required this.note,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Row ──────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final OrderBookLevelWithTotal level;
  final double maxTotal;

  const _OrderRow({required this.level, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final pct = maxTotal > 0 ? level.total / maxTotal : 0.0;
    final color = level.isBid ? AppColors.brandGreen : AppColors.brandRed;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment:
                level.isBid ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: pct * 0.6,
              child: Container(color: color.withAlpha(12)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '\$${level.price.toStringAsFixed(level.price >= 100 ? 1 : 2)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                level.quantity.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  level.total.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Spread Tile ────────────────────────────────────────────────────────────────

class _SpreadTile extends StatelessWidget {
  final String value, label;
  final Color color;

  const _SpreadTile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
