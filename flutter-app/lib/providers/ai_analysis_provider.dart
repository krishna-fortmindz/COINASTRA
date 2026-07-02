import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiAnalysisNotifier extends ChangeNotifier {
  String _selectedCoin = 'BTC';
  String get selectedCoin => _selectedCoin;

  void selectCoin(String coin) {
    if (_selectedCoin == coin) return;
    _selectedCoin = coin;
    notifyListeners();
  }
}

final aiAnalysisProvider = ChangeNotifierProvider(
  (ref) => AiAnalysisNotifier(),
);
