import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../../providers/dashboard_provider.dart';

class TrendingCoins extends ConsumerWidget {
  const TrendingCoins({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingProvider);
    return async.when(
      loading: _buildShimmer,
      error: (_, __) => _buildContent(context, ref, _fallback),
      data: (coins) => _buildContent(context, ref, coins.isNotEmpty ? coins : _fallback),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, List<TrendingCoin> coins) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Trending', subtitle: 'Most searched · Last 24h')),
              GestureDetector(
                onTap: () => _showAllTrending(context, coins),
                child: const Text('View All', style: TextStyle(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...coins.take(6).toList().asMap().entries.map((e) =>
            _TrendingRow(
              rank: e.key + 1,
              coin: e.value,
              onTap: () => context.go('/trade-now?coin=${e.value.symbol}'),
            )),
        ],
      ),
    );
  }

  void _showAllTrending(BuildContext context, List<TrendingCoin> coins) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (innerCtx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All Trending Coins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Search TextField
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
                        onChanged: (v) => setSheetState(() => searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search any coin...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  // List
                  Expanded(
                    child: searchQuery.length >= 2
                        ? Consumer(
                            builder: (ctx, ref, _) {
                              final resultsAsync = ref.watch(coinSearchProvider(searchQuery));
                              return resultsAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brandGreen, strokeWidth: 2),
                                ),
                                error: (_, __) => const Center(
                                  child: Text('Error loading results',
                                    style: TextStyle(fontSize: 13, color: AppColors.brandRed)),
                                ),
                                data: (results) {
                                  if (results.isEmpty) {
                                    return const Center(
                                      child: Text('No coins found',
                                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                    );
                                  }
                                  return ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                    itemCount: results.length,
                                    itemBuilder: (_, i) {
                                      final coin = results[i];
                                      final change = coin.priceChange24h;
                                      final changeStr =
                                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
                                      final positive = change >= 0;
                                      final color = positive ? AppColors.brandGreen : AppColors.brandRed;
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(sheetCtx).pop();
                                          context.go('/trade-now?coin=${coin.symbol}');
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              // Avatar
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    coin.symbol[0],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
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
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: color.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  changeStr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: color,
                                                    fontFamily: 'JetBrainsMono',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: coins.length,
                            itemBuilder: (_, i) => _TrendingRow(
                              rank: i + 1,
                              coin: coins[i],
                              onTap: () {
                                Navigator.of(sheetCtx).pop();
                                context.go('/trade-now?coin=${coins[i].symbol}');
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static final _fallback = [
    const TrendingCoin(id: 'bitcoin',  symbol: 'BTC',  name: 'Bitcoin',     priceChange24h: 2.4),
    const TrendingCoin(id: 'solana',   symbol: 'SOL',  name: 'Solana',      priceChange24h: -0.9),
    const TrendingCoin(id: 'pepe',     symbol: 'PEPE', name: 'Pepe',        priceChange24h: 18.2),
    const TrendingCoin(id: 'arweave',  symbol: 'AR',   name: 'Arweave',     priceChange24h: 42.0),
    const TrendingCoin(id: 'ondo',     symbol: 'ONDO', name: 'Ondo Finance', priceChange24h: 8.7),
    const TrendingCoin(id: 'dogwifhat',symbol: 'WIF',  name: 'Dogwifhat',   priceChange24h: -3.2),
  ];
}

class _TrendingRow extends StatelessWidget {
  final int rank;
  final TrendingCoin coin;
  final VoidCallback? onTap;
  const _TrendingRow({required this.rank, required this.coin, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text('#$rank',
                style: const TextStyle(
                  fontSize: 10, color: AppColors.textDisabled, fontFamily: 'JetBrainsMono')),
            ),
            const SizedBox(width: 8),
            Text(coin.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.symbol,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(coin.name,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (coin.positive ? AppColors.brandGreen : AppColors.brandRed).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(coin.formattedChange,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono',
                  color: coin.positive ? AppColors.brandGreen : AppColors.brandRed,
                )),
            ),
          ],
        ),
      ),
    );
  }
}
