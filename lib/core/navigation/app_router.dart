import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/exams/screens/exam_list_screen.dart';
import '../../features/years/screens/year_list_screen.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/papers/screens/papers_screen.dart';
import '../../features/viewer/screens/pdf_viewer_screen.dart';
import '../../features/downloads/screens/downloads_screen.dart';
import '../../features/privacy/screens/privacy_policy_screen.dart';

// Route name constants — use these instead of raw strings.
class AppRoutes {
  AppRoutes._();
  static const String splash     = 'splash';
  static const String home       = 'home';
  static const String years      = 'years';
  static const String categories = 'categories';
  static const String papers     = 'papers';
  static const String viewer     = 'viewer';
  static const String downloads  = 'downloads';
  static const String privacy    = 'privacy';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Home: Exam list ───────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: AppRoutes.home,
        builder: (context, state) => const ExamListScreen(),
      ),

      // ── Year list ─────────────────────────────────────────────────────
      GoRoute(
        path: '/exam/:examId/years',
        name: AppRoutes.years,
        builder: (context, state) => YearListScreen(
          examId:   state.pathParameters['examId']!,
          examName: state.uri.queryParameters['examName'] ?? '',
        ),
      ),

      // ── Category list ─────────────────────────────────────────────────
      GoRoute(
        path: '/exam/:examId/years/:year/categories',
        name: AppRoutes.categories,
        builder: (context, state) => CategoryScreen(
          examId:   state.pathParameters['examId']!,
          examName: state.uri.queryParameters['examName'] ?? '',
          year:     int.parse(state.pathParameters['year']!),
        ),
      ),

      // ── Papers list ───────────────────────────────────────────────────
      GoRoute(
        path: '/exam/:examId/years/:year/categories/:categoryId/papers',
        name: AppRoutes.papers,
        builder: (context, state) => PapersScreen(
          examId:       state.pathParameters['examId']!,
          examName:     state.uri.queryParameters['examName'] ?? '',
          year:         int.parse(state.pathParameters['year']!),
          categoryId:   state.pathParameters['categoryId']!,
          categoryName: state.uri.queryParameters['categoryName'] ?? '',
        ),
      ),

      // ── PDF Viewer ────────────────────────────────────────────────────
      GoRoute(
        path: '/viewer',
        name: AppRoutes.viewer,
        builder: (context, state) => PDFViewerScreen(
          pdfUrl:       state.uri.queryParameters['url'] ?? '',
          title:        state.uri.queryParameters['title'] ?? 'PDF Viewer',
          localPath:    state.uri.queryParameters['localPath'],
          paperId:      state.uri.queryParameters['paperId'],
          examId:       state.uri.queryParameters['examId'],
          year:         int.tryParse(state.uri.queryParameters['year'] ?? ''),
          categoryId:   state.uri.queryParameters['categoryId'],
          categoryName: state.uri.queryParameters['categoryName'],
        ),
      ),

      // ── Downloads ─────────────────────────────────────────────────────
      GoRoute(
        path: '/downloads',
        name: AppRoutes.downloads,
        builder: (context, state) => const DownloadsScreen(),
      ),

      // ── Privacy Policy ────────────────────────────────────────────────
      GoRoute(
        path: '/privacy',
        name: AppRoutes.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],

    // ── 404 fallback ─────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ),
  );
});
