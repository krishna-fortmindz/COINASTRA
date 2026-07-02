import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiSummaryNotifier extends ChangeNotifier {
  static const _defaultText =
      'BTC is showing strong bullish momentum. RSI at 67 — not yet overbought. '
      r'Key resistance at $98.4K. Funding rates remain neutral. ETF inflows are positive '
      'for the 3rd consecutive day. Consider scaling positions on pullbacks to the '
      r'$95K support zone. Watch for a possible liquidity sweep below $96K before continuation.';

  String _fullText = _defaultText;
  int _charCount = 0;
  bool _isTyping = true;
  bool _disposed = false;

  String get fullText => _fullText;
  int get charCount => _charCount;
  bool get isTyping => _isTyping;

  AiSummaryNotifier() {
    _startTyping();
  }

  /// Called when live AI summary arrives from the API.
  /// Resets the typewriter animation with the new text.
  void setText(String text) {
    if (text.isEmpty || text == _fullText) return;
    _fullText = text;
    _charCount = 0;
    _isTyping = true;
    notifyListeners();
    _startTyping();
  }

  void _startTyping() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 18));
      if (_disposed) return false;
      if (_charCount < _fullText.length) {
        _charCount++;
        notifyListeners();
        return true;
      }
      _isTyping = false;
      notifyListeners();
      return false;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// Not autoDispose — animation plays once and stays complete across navigation
final aiSummaryProvider = ChangeNotifierProvider(
  (ref) => AiSummaryNotifier(),
);