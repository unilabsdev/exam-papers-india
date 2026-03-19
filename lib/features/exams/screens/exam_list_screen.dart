import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/providers/realtime_provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_card.dart';

class ExamListScreen extends ConsumerStatefulWidget {
  const ExamListScreen({super.key});

  @override
  ConsumerState<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends ConsumerState<ExamListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsProvider);
    final theme = Theme.of(context);

    ref.listen(newPaperStreamProvider, (_, __) {
      ref.invalidate(examsProvider);
    });

    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OfflineBanner(
      child: Scaffold(
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

            // ── Search bar ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  hintText: 'Search exams…',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _query.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _query = ''),
                          )
                        ]
                      : null,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                      cs.surfaceContainerHighest),
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
            ),

            // ── Section header ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      _query.isEmpty ? 'All Exams' : 'Results',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    examsAsync.whenData((exams) {
                      final filtered = _filtered(exams);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filtered.length} exams',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).value ??
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
                child: AppErrorWidget(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(examsProvider),
                ),
              ),
              data: (exams) {
                final filtered = _filtered(exams);

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyWidget(
                      title: _query.isEmpty ? 'No Exams Found' : 'No Results',
                      subtitle: _query.isEmpty
                          ? 'No exam papers are available at the moment.\nCheck back soon.'
                          : 'No exams match "$_query".',
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
                        final exam = filtered[index];
                        return ExamCard(
                          exam: exam,
                          onTap: () => context.pushNamed(
                            AppRoutes.years,
                            pathParameters: {'examId': exam.id},
                            queryParameters: {'examName': exam.shortName},
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List _filtered(List exams) {
    if (_query.isEmpty) return exams;
    final q = _query.toLowerCase();
    return exams
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.shortName.toLowerCase().contains(q))
        .toList();
  }
}
