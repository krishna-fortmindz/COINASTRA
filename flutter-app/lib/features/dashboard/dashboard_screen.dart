import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/ai_summary_provider.dart';
import '../../core/remote/web_socket_baseclass.dart';
import 'widgets/market_overview_card.dart';
import 'widgets/fear_greed_widget.dart';
import 'widgets/funding_rate_panel.dart';
import 'widgets/whale_alerts.dart';
import 'widgets/ai_summary_card.dart';
import 'widgets/portfolio_overview.dart';
import 'widgets/trending_coins.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Feed live AI summary text into the typewriter animation when data arrives
    ref.listen(dashboardSummaryProvider, (_, next) {
      next.whenData((summary) {
        if (summary.aiSummary.isNotEmpty) {
          ref.read(aiSummaryProvider).setText(summary.aiSummary);
        }
      });
    });

    final connectionAsync = ref.watch(socketConnectionProvider);
    final isConnected = connectionAsync.value ?? false;
    final isConnecting = connectionAsync.isLoading;

    final String subtitle;
    final String bannerText;
    final Color bannerColor;
    final IconData bannerIcon;

    if (isConnected) {
      subtitle = 'Connected · Live price feed';
      bannerText = '';
      bannerColor = AppColors.brandGreen;
      bannerIcon = Icons.check_circle_outline_rounded;
    } else if (isConnecting) {
      subtitle = 'Reconnecting to websocket...';
      bannerText = 'Connecting to real-time price feeds...';
      bannerColor = AppColors.brandAmber;
      bannerIcon = Icons.sync_rounded;
    } else {
      subtitle = 'Offline · Falling back to cached data';
      bannerText = 'Real-time connection paused. Tap Refresh to try again.';
      bannerColor = AppColors.brandRed;
      bannerIcon = Icons.warning_amber_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                _DashboardHeader(),
                const SizedBox(height: 20),

                // Animated reconnect/offline banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: !isConnected ? 44 : 0,
                  margin: EdgeInsets.only(bottom: !isConnected ? 16 : 0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(bannerIcon, color: bannerColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            bannerText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: bannerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Market overview cards
                SectionHeader(
                  title: 'Market Overview',
                  subtitle: subtitle,
                ),
                const SizedBox(height: 12),
                const MarketOverviewCards(),
                const SizedBox(height: 20),

                // AI Summary + Fear & Greed
                LayoutBuilder(builder: (_, c) {
                  if (c.maxWidth < 700) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiSummaryCard(),
                        SizedBox(height: 16),
                        FearGreedWidget(),
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: AiSummaryCard()),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: FearGreedWidget()),
                    ],
                  );
                }),
                const SizedBox(height: 20),

                // Funding + Portfolio
                LayoutBuilder(builder: (_, c) {
                  if (c.maxWidth < 700) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FundingRatePanel(),
                        SizedBox(height: 16),
                        PortfolioOverview(),
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: FundingRatePanel()),
                      SizedBox(width: 16),
                      Expanded(child: PortfolioOverview()),
                    ],
                  );
                }),
                const SizedBox(height: 20),

                // Trending + Whale Alerts
                const SectionHeader(title: 'Trending & Whale Activity'),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (_, c) {
                  if (c.maxWidth < 700) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrendingCoins(),
                        SizedBox(height: 16),
                        WhaleAlerts(),
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: TrendingCoins()),
                      SizedBox(width: 16),
                      Expanded(child: WhaleAlerts()),
                    ],
                  );
                }),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Market at a glance — live data',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        _QuickAction(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onTap: () {
            ref.invalidate(marketCoinsProvider);
            ref.invalidate(dashboardSummaryProvider);
            DashboardSocket.instance.reconnect();
          },
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
