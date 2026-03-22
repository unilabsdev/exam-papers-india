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

  // ── Firebase Core (critical — must complete before runApp so Crashlytics
  //    can catch errors from the very first frame) ───────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wire up Crashlytics error handlers immediately after Firebase is ready
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── System UI (local, instant) ────────────────────────────────────────────
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

  // ── Start the app immediately ─────────────────────────────────────────────
  runApp(const ProviderScope(child: ExamPapersApp()));

  // ── Non-critical SDKs — initialized in background after first frame ───────
  // The app is already visible. These will complete when ready (online or off).
  unawaited(
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true),
  );
  unawaited(
    AdService.initialize(),
  );
  unawaited(
    Supabase.initialize(
      url:     AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    ).catchError((Object _) => Supabase.instance),
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
