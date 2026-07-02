import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for the globally selected coin.
/// Written by global search and every per-page coin selector.
/// Persists across navigation, resets to BTC on app restart.
final selectedCoinProvider = StateProvider<String>((ref) => 'BTC');
