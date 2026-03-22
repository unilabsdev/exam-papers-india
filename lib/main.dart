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
import 'services/supabase_service.dart';

// ── Synchronous main — app ALWAYS renders immediately ────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only truly synchronous, instant calls before runApp.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Render the app immediately — nothing can block this.
  runApp(const ProviderScope(child: ExamPapersApp()));

  // Initialize all SDKs in the background after the first frame is visible.
  unawaited(_initSdks());
}

/// All SDK initialization runs here — in the background, after runApp().
/// Each SDK has an independent timeout so one hanging SDK can't block others.
Future<void> _initSdks() async {
  // Screen orientation (visual only, non-critical)
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  // Firebase (needed for Crashlytics)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    unawaited(
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true),
    );
  } catch (_) {
    // Firebase unavailable — app still works, just no crash reporting
  }

  // AdMob (ads only — fully optional)
  unawaited(AdService.initialize().catchError((_) {}));

  // Supabase — 5s timeout so offline users see error state quickly
  try {
    await Supabase.initialize(
      url:     AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    // Offline or timed out — providers will show the offline error state
  } finally {
    // Always unblock data providers, online or offline
    markSupabaseReady();
  }
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
