import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shared_pref_services.dart';
import '../services/pref_keys.dart';

/// Single source of truth for the globally selected coin.
/// Persists the selection to SharedPreferences so it survives
/// browser tab switches, page refreshes, and app restarts.
class SelectedCoinNotifier extends Notifier<String> {
  @override
  String build() {
    return SharedPreferenceService.getValue<String>(
          PrefKeys.selectedCoin,
          defaultValue: 'BTC',
        ) ??
        'BTC';
  }

  void set(String coin) {
    if (state == coin) return;
    state = coin;
    SharedPreferenceService.setValue(PrefKeys.selectedCoin, coin);
  }
}

final selectedCoinProvider =
    NotifierProvider<SelectedCoinNotifier, String>(SelectedCoinNotifier.new);
