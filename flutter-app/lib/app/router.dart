import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../features/dashboard/dashboard_screen.dart';
import '../features/ai_analysis/ai_analysis_screen.dart';
import '../features/charts/charts_screen.dart';
import '../features/market_memory/market_memory_screen.dart';
import '../features/news_sentiment/news_sentiment_screen.dart';
import '../features/new_listings/new_listings_screen.dart';
import '../features/risk_management/risk_management_screen.dart';
import '../features/trade_journal/trade_journal_screen.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/trade_now/trade_now_screen.dart';
import '../features/token_unlocks/token_unlocks_screen.dart';
import '../features/orderbook/orderbook_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/predictions/predictions_leaderboard_screen.dart';
import '../core/widgets/app_shell.dart';
import '../providers/auth_provider.dart';

// ── Auth guard ────────────────────────────────────────────────────────────────

class _AuthGuardedPage extends ConsumerWidget {
  final Widget child;
  const _AuthGuardedPage({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider);
    if (loggedIn) return child;
    return _LoginPrompt(child: child);
  }
}

class _LoginPrompt extends StatelessWidget {
  final Widget child;
  const _LoginPrompt({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF141519),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2D36)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00C896), Color(0xFF00A876)]),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.black, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('Sign In Required', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
              )),
              const SizedBox(height: 8),
              const Text(
                'Create a free account to access your portfolio, journal, and personalized settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    html.window.location.assign('/auth/login');
                  },
                  child: const Text('Sign In / Create Account',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Maybe Later',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

final router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(path: '/app', redirect: (_, __) => '/dashboard'),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/trade-now', builder: (c, s) => const TradeNowScreen()),
        GoRoute(path: '/analysis', builder: (c, s) => const AiAnalysisScreen()),
        GoRoute(path: '/charts', builder: (c, s) => const ChartsScreen()),
        GoRoute(path: '/memory', builder: (c, s) => const MarketMemoryScreen()),
        GoRoute(path: '/sentiment', builder: (c, s) => const NewsSentimentScreen()),
        GoRoute(path: '/listings', builder: (c, s) => const NewListingsScreen()),
        GoRoute(path: '/orderbook', builder: (c, s) => const OrderbookScreen()),
        GoRoute(path: '/token-unlocks', builder: (c, s) => const TokenUnlocksScreen()),
        GoRoute(path: '/portfolio', builder: (c, s) => const _AuthGuardedPage(child: PortfolioScreen())),
        GoRoute(path: '/risk', builder: (c, s) => const RiskManagementScreen()),
        GoRoute(path: '/journal', builder: (c, s) => const _AuthGuardedPage(child: TradeJournalScreen())),
        GoRoute(path: '/chat', builder: (c, s) => const AiChatScreen()),
        GoRoute(path: '/profile', builder: (c, s) => const _AuthGuardedPage(child: ProfileScreen())),
        GoRoute(path: '/predictions', builder: (c, s) => const PredictionsLeaderboardScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    backgroundColor: Color(0xFF0A0B0F),
    body: Center(
      child: Text(
        'Page not found',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
);
