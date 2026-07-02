import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          _SidebarHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('OVERVIEW'),
                  _SidebarItem('/dashboard', Icons.dashboard_rounded, 'Dashboard', currentRoute),
                  _SidebarItem('/trade-now', Icons.bolt_rounded, 'Trade Now?', currentRoute,
                    badge: 'SIGNAL'),
                  const SizedBox(height: 16),
                  const _SectionLabel('AI INTELLIGENCE'),
                  _SidebarItem('/analysis', Icons.psychology_rounded, 'AI Analysis', currentRoute),
                  _SidebarItem('/memory', Icons.history_edu_rounded, 'Market Memory', currentRoute),
                  _SidebarItem('/chat', Icons.chat_bubble_outline_rounded, 'AI Chat', currentRoute),
                  _SidebarItem('/predictions', Icons.leaderboard_rounded, 'AI Accuracy', currentRoute),
                  const SizedBox(height: 16),
                  const _SectionLabel('MARKET'),
                  _SidebarItem('/charts', Icons.candlestick_chart_rounded, 'Charts', currentRoute),
                  _SidebarItem('/orderbook', Icons.menu_rounded, 'Order Book', currentRoute),
                  _SidebarItem('/sentiment', Icons.newspaper_rounded, 'News', currentRoute),
                  _SidebarItem('/listings', Icons.new_releases_rounded, 'New Listings', currentRoute,
                    badge: 'HOT'),
                  const SizedBox(height: 16),
                  const _SectionLabel('ON-CHAIN'),
                  _SidebarItem('/token-unlocks', Icons.lock_open_rounded, 'Token Unlocks', currentRoute),
                  const SizedBox(height: 16),
                  const _SectionLabel('TRADING'),
                  _SidebarItem('/risk', Icons.shield_rounded, 'Risk Manager', currentRoute),
                  _SidebarItem('/journal', Icons.book_rounded, 'Trade Journal', currentRoute),
                  const SizedBox(height: 16),
                  const _SectionLabel('ACCOUNT'),
                  _SidebarItem('/profile', Icons.person_rounded, 'Profile', currentRoute),
                ],
              ),
            ),
          ),
          _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientGreen,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Trading',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              Text(
                'Copilot',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandGreen,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textDisabled,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String route;
  final IconData icon;
  final String label;
  final String currentRoute;
  final String? badge;

  const _SidebarItem(this.route, this.icon, this.label, this.currentRoute,
      {this.badge});

  @override
  Widget build(BuildContext context) {
    final active = currentRoute == route;
    final isSignal = badge == 'SIGNAL';

    return GestureDetector(
      onTap: () => Router.neglect(context, () => context.go(route)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.brandGreen.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.brandGreen.withValues(alpha: 0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? AppColors.brandGreen : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSignal
                      ? AppColors.brandGreen.withValues(alpha: 0.15)
                      : badge == 'HOT'
                          ? AppColors.brandGreen.withValues(alpha: 0.15)
                          : AppColors.brandRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSignal || badge == 'HOT'
                        ? AppColors.brandGreen
                        : AppColors.brandRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: authState.isLoggedIn
          ? _LoggedInFooter(authState: authState, ref: ref)
          : _SignInFooter(),
    );
  }
}

class _LoggedInFooter extends StatelessWidget {
  final AuthState authState;
  final WidgetRef ref;
  const _LoggedInFooter({required this.authState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = authState.user;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';
    final displayName = user?.name ?? 'User';

    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.brandGreen,
                )),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                  ), overflow: TextOverflow.ellipsis),
                  const Text('Authenticated', style: TextStyle(
                    fontSize: 10, color: AppColors.brandGreen,
                  )),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              child: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => html.window.location.assign('/auth/login'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_rounded, size: 15, color: AppColors.brandGreen),
            SizedBox(width: 8),
            Text('Sign In / Sign Up', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandGreen,
            )),
          ],
        ),
      ),
    );
  }
}