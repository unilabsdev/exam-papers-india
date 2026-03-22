import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/providers/realtime_provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_card.dart';

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);
    final theme = Theme.of(context);

    ref.listen(newPaperStreamProvider, (_, __) {
      ref.invalidate(examsProvider);
    });

    ref.listen(isOfflineProvider, (prev, isOffline) {
      if (isOffline && prev == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re offline — some content may not load'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: const AppDrawer(),
        body: CustomScrollView(
          slivers: [
            // ── Large collapsing app bar ──────────────────────────────────
            SliverAppBar.large(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: cs.surface,
              surfaceTintColor: cs.surface,
              shadowColor: cs.outlineVariant,
              title: Text(
                'Exam Papers India',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous Year Question Papers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exam Papers India',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Menu',
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => ref.read(themeProvider.notifier).toggle(),
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                  tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                ),
                IconButton(
                  onPressed: () => context.push('/downloads'),
                  icon: const Icon(Icons.download_done_rounded),
                  tooltip: 'Downloads',
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Section header ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'All Exams',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    examsAsync.whenData((exams) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${exams.length} exams',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).asData?.value ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            examsAsync.when(
              loading: () => const SliverFillRemaining(
                child: AppLoadingWidget(message: 'Loading exams…'),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _OfflineErrorWidget(
                  onRetry: () => ref.invalidate(examsProvider),
                  onGoToDownloads: () => context.push('/downloads'),
                ),
              ),
              data: (exams) {
                if (exams.isEmpty) {
                  return const SliverFillRemaining(
                    child: AppEmptyWidget(
                      title: 'No Exams Found',
                      subtitle: 'No exam papers are available at the moment.\nCheck back soon.',
                      icon: Icons.school_rounded,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppConstants.examGridCrossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: AppConstants.examCardAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exam = exams[index];
                        return ExamCard(
                          exam: exam,
                          onTap: () => context.pushNamed(
                            AppRoutes.years,
                            pathParameters: {'examId': exam.id},
                            queryParameters: {'examName': exam.shortName},
                          ),
                        );
                      },
                      childCount: exams.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
}

class _OfflineErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onGoToDownloads;

  const _OfflineErrorWidget({
    required this.onRetry,
    required this.onGoToDownloads,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connect to the internet to browse exams.\nYou can still read your downloaded papers offline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGoToDownloads,
                icon: const Icon(Icons.download_done_rounded, size: 18),
                label: const Text('Go to Downloads'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
