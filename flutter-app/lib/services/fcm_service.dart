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

  // Holds the last known FCM token so we can retry registration after login
  static String? _lastToken;

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
        await _register(token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        log('[FCM] Token refreshed');
        _lastToken = newToken;
        _register(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) {
        log('[FCM] Foreground message: ${message.notification?.title}');
        final n = message.notification;
        if (n != null) {
          js.JsObject(
            js.context['Notification'] as js.JsFunction,
            [
              n.title ?? 'CoinPilot',
              js.JsObject.jsify({
                'body': n.body ?? '',
                'icon': '/icons/Icon-192.png',
              }),
            ],
          );
        }
      });
    } catch (e) {
      log('[FCM] Init error: $e');
    }
  }

  /// Call this after login / auth state confirmed — retries storing the FCM
  /// token if the initial registration failed (e.g. 401 during signup flow).
  static Future<void> retryRegistration() async {
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

  static Future<void> _register(String token) async {
    try {
      await ApiClient.instance.put(
        EndPoints.fcmToken,
        data: {'token': token},
      );
      log('[FCM] Token registered with backend');
    } catch (e) {
      log('[FCM] Token registration skipped: $e');
    }
  }
}
