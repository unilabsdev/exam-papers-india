import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/ad_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route all Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Route async/platform errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Enable Analytics data collection
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // ── AdMob ─────────────────────────────────────────────────────────────────
  await AdService.initialize();

  // ── Supabase ──────────────────────────────────────────────────────────────
  // Timeout prevents hanging forever when the device is offline.
  // The app will still launch; network features will show error states.
  try {
    await Supabase.initialize(
      url:     AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    ).timeout(const Duration(seconds: 5));
  } on TimeoutException catch (_) {
    // Offline at startup — app will start normally; downloads still work
  } catch (_) {
    // Any other init error — still start the app
  }

  // ── System UI ─────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: ExamPapersApp(),
    ),
  );
}

class ExamPapersApp extends ConsumerWidget {
  const ExamPapersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
