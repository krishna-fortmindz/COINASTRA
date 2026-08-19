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
        'badge': '/icons/Icon-192.png',
        'tag': 'coinpilot-alert',
        'renotify': true,
      });

      final navigator = js.context['navigator'];
      if (navigator == null) return;

      final swContainer = navigator['serviceWorker'];
      if (swContainer == null) {
        _directNotification(title, opts);
        return;
      }

      final ready = swContainer['ready'];
      if (ready == null) {
        _directNotification(title, opts);
        return;
      }

      // JsFunction.withThis: first param = JS `this`, second = resolved value.
      // For a Promise .then callback `this` is undefined; reg is the registration.
      (ready as js.JsObject).callMethod('then', [
        js.JsFunction.withThis((_, dynamic reg) {
          try {
            (reg as js.JsObject).callMethod('showNotification', [title, opts]);
          } catch (_) {
            _directNotification(title, opts);
          }
        }),
      ]);
    } catch (_) {}
  }

  static void _directNotification(String title, js.JsObject opts) {
    try {
      final notifCtor = js.context['Notification'] as js.JsFunction?;
      if (notifCtor != null) js.JsObject(notifCtor, [title, opts]);
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
