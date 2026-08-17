import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/shared_pref_services.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceService.init();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FcmService.init();
  } catch (e) {
    log('[Firebase] Init failed — notifications disabled: $e');
  }

  runApp(
    const ProviderScope(
      child: AiTradingCopilotApp(),
    ),
  );
}
