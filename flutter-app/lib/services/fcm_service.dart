import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';

class FcmService {
  FcmService._();

  // Get this from: Firebase Console → Project Settings →
  // Cloud Messaging → Web configuration → Generate key pair
  static const String _vapidKey =
      'BCJtfujppseHuv0YNjtyujhXYVTyT4UVATgT9m1SBuR4wk2Ka3kx_duFzWdFoaK2h0_cnAyk3zHUPT7w9ZS3KmQ';

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
        log('[FCM] Token obtained, registering with backend');
        await _register(token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        log('[FCM] Token refreshed');
        _register(newToken);
      });

      // Foreground message handler — shown as in-app overlay by the UI layer
      FirebaseMessaging.onMessage.listen((message) {
        log('[FCM] Foreground message: ${message.notification?.title}');
      });
    } catch (e) {
      log('[FCM] Init error: $e');
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
      // Silently fail if user is not logged in (401) — re-registers on next app open after login
      log('[FCM] Token registration skipped: $e');
    }
  }
}
