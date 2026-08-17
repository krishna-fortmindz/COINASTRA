import 'dart:developer';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

class FcmService {
  FcmService._();

  static const String _vapidKey =
      'BCJtfujppseHuv0YNjtyujhXYVTyT4UVATgT9m1SBuR4wk2Ka3kx_duFzWdFoaK2h0_cnAyk3zHUPT7w9ZS3KmQ';

  static String? _lastToken;
  static bool _registered = false;

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        log('[FCM] Notification permission denied');
        return;
      }

      final token = await messaging.getToken(vapidKey: _vapidKey);
      if (token != null) {
        _lastToken = token;
        log('[FCM] Token: $token');
      }

      messaging.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
        if (_registered) _register(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) {
        log('[FCM] Foreground message: ${message.notification?.title}');
        final n = message.notification;
        if (n != null) _showNotification(n.title ?? 'CoinPilot', n.body ?? '');
      });
    } catch (e) {
      log('[FCM] Init error: $e');
    }
  }

  /// Call this after login / auth state confirmed — retries storing the FCM
  /// token if the initial registration failed (e.g. 401 during signup flow).
  static Future<void> retryRegistration() async {
    if (_registered) return;
    try {
      final token = _lastToken ??
          await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey);
      if (token != null) {
        _lastToken = token;
        await _register(token);
      }
    } catch (e) {
      log('[FCM] Retry registration error: $e');
    }
  }

  static void resetRegistration() {
    _registered = false;
  }

  static void _showNotification(String title, String body) {
    try {
      final opts = js.JsObject.jsify({
        'body': body,
        'icon': '/icons/Icon-192.png',
      });

      // Use service worker showNotification — works on mobile web & desktop
      final sw = js.context['navigator']['serviceWorker'] as js.JsObject?;
      final ready = sw?['ready'];
      if (ready != null) {
        (ready as js.JsObject).callMethod('then', [
          js.JsFunction.withThis((thisArg, reg) {
            try {
              (reg as js.JsObject).callMethod('showNotification', [title, opts]);
            } catch (_) {}
          }),
        ]);
        return;
      }

      // Fallback: direct Notification constructor (desktop only)
      js.JsObject(
        js.context['Notification'] as js.JsFunction,
        [title, opts],
      );
    } catch (_) {}
  }

  static Future<void> _register(String token) async {
    try {
      await ApiClient.instance.put(
        EndPoints.fcmToken,
        data: {'token': token},
      );
      log('[FCM] Token registered with backend');
      _registered = true;
    } catch (_) {}
  }
}
