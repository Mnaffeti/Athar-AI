import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

// Publishable values, safe to ship in the app; override with --dart-define.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ysrusubsulkfemzrlxvx.supabase.co',
);
const _supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_Xoexrdp4-ifBrJ52XUCOvw_0TrdUB4K',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  await NotificationService.initialize();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const AtharApp());
}

class AtharApp extends StatelessWidget {
  const AtharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
