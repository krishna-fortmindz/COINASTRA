import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'feedback_widget.dart';
import 'sidebar.dart';
import 'top_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    final mainContent = isDesktop
        ? Row(
            children: [
              const AppSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const TopBar(),
                    Expanded(child: ClipRect(child: child)),
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              const TopBar(),
              Expanded(child: child),
              _BottomNav(currentRoute: GoRouterState.of(context).uri.path),
            ],
          );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          mainContent,
          const FeedbackTab(),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentRoute;
  const _BottomNav({required this.currentRoute});

  static const _moreRoutes = {
    '/analysis', '/memory', '/sentiment', '/listings',
    '/token-unlocks',
    '/risk', '/journal', '/chat', '/profile', '/predictions',
  };

  bool get _moreActive => _moreRoutes.contains(currentRoute);

  @override
  Widget build(BuildContext context) {
    final mainItems = [
      _NavItem('/dashboard', Icons.dashboard_rounded, 'Home'),
      _NavItem('/trade-now', Icons.bolt_rounded, 'Signal'),
      _NavItem('/charts', Icons.candlestick_chart_rounded, 'Charts'),
      _NavItem('/orderbook', Icons.menu_book_rounded, 'Book'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Main nav items
            ...mainItems.map((item) {
              final active = currentRoute == item.route;
              return Expanded(
                child: GestureDetector(
                  onTap: () => Router.neglect(context, () => context.go(item.route)),
                  behavior: HitTestBehavior.opaque,
                  child: _NavTab(icon: item.icon, label: item.label, active: active),
                ),
              );
            }),
            // More button
            Expanded(
              child: GestureDetector(
                onTap: () => _showMore(context),
                behavior: HitTestBehavior.opaque,
                child: _NavTab(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  active: _moreActive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(currentRoute: currentRoute),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavTab({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? AppColors.brandGreen : AppColors.textMuted),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: active ? AppColors.brandGreen : AppColors.textMuted,
          )),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  _NavItem(this.route, this.icon, this.label);
}

class _MoreSheet extends StatelessWidget {
  final String currentRoute;
  const _MoreSheet({required this.currentRoute});

  static const _sections = [
    _MoreSection('AI INTELLIGENCE', [
      _MoreEntry('/analysis', Icons.psychology_rounded, 'AI Analysis', AppColors.brandPurple),
      _MoreEntry('/memory', Icons.history_edu_rounded, 'Market Memory', AppColors.brandBlue),
      _MoreEntry('/chat', Icons.chat_bubble_outline_rounded, 'AI Chat', AppColors.brandGreen),
      _MoreEntry('/predictions', Icons.leaderboard_rounded, 'AI Accuracy', AppColors.brandAmber),
    ]),
    _MoreSection('MARKET', [
      _MoreEntry('/sentiment', Icons.newspaper_rounded, 'News', AppColors.brandAmber),
      _MoreEntry('/listings', Icons.new_releases_rounded, 'New Listings', AppColors.brandGreen),
      _MoreEntry('/orderbook', Icons.menu_rounded, 'Order Book', AppColors.brandBlue),
    ]),
    _MoreSection('ON-CHAIN', [
      _MoreEntry('/token-unlocks', Icons.lock_open_rounded, 'Token Unlocks', AppColors.brandAmber),
    ]),
    _MoreSection('TRADING', [
      _MoreEntry('/risk', Icons.shield_rounded, 'Risk Manager', AppColors.brandRed),
      _MoreEntry('/journal', Icons.book_rounded, 'Trade Journal', AppColors.brandBlue),
    ]),
    _MoreSection('ACCOUNT', [
      _MoreEntry('/profile', Icons.person_rounded, 'Profile', AppColors.textMuted),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map((section) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(section.label, style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppColors.textDisabled, letterSpacing: 1.2,
                      )),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.5,
                      children: section.entries.map((e) {
                        final active = currentRoute == e.route;
                        return GestureDetector(
                          onTap: () => Router.neglect(context, () {
                            Navigator.of(context).pop();
                            context.go(e.route);
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: active
                                  ? e.color.withAlpha(20)
                                  : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? e.color.withAlpha(50)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(e.icon, size: 20,
                                  color: active ? e.color : AppColors.textMuted),
                                const SizedBox(height: 6),
                                Text(e.label, textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w500,
                                    color: active ? Colors.white : AppColors.textMuted,
                                  )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreSection {
  final String label;
  final List<_MoreEntry> entries;
  const _MoreSection(this.label, this.entries);
}

class _MoreEntry {
  final String route, label;
  final IconData icon;
  final Color color;
  const _MoreEntry(this.route, this.icon, this.label, this.color);
}