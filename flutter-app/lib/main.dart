import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'services/shared_pref_services.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceService.init();
  runApp(
    const ProviderScope(
      child: AiTradingCopilotApp(),
    ),
  );
}
