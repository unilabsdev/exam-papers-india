import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../../viewer/providers/pdf_cache_provider.dart';
import '../providers/paper_provider.dart';
import '../repositories/paper_repository.dart';
import '../widgets/paper_tile.dart';

class PapersScreen extends ConsumerWidget {
  final String examId;
  final String examName;
  final int year;
  final String categoryId;
  final String categoryName;

  const PapersScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.year,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = PaperParams(
      examId:     examId,
      year:       year,
      categoryId: categoryId,
    );
    final papersAsync = ref.watch(papersProvider(params));
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final bookmarkedIds = ref.watch(
      bookmarkProvider.select((list) => list.map((p) => p.id).toSet()),
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _AppBarTitle(
          title:    categoryName,
          subtitle: '$examName · $year',
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: papersAsync.when(
        loading: () =>
            const AppLoadingWidget(message: 'Loading papers…'),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(papersProvider(params)),
        ),
        data: (papers) {
          // Prefetch PDFs in the background so they're cached before user taps Open
          for (final p in papers) {
            if (p.pdfUrl != null && p.pdfUrl!.isNotEmpty) {
              ref.read(pdfCacheProvider(p.pdfUrl!).future).ignore();
            }
          }

          if (papers.isEmpty) {
            return const AppEmptyWidget(
              title: 'No Papers Found',
              subtitle:
                  'No question papers are available for this selection.',
              icon: Icons.description_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: papers.length,
            itemBuilder: (context, index) {
              final paper = papers[index];
              final hasFile =
                  paper.pdfUrl != null && paper.pdfUrl!.isNotEmpty;
              return PaperTile(
                paper: paper,
                isBookmarked: bookmarkedIds.contains(paper.id),
                isFileAvailable: hasFile,
                onBookmarkToggle: hasFile
                    ? () => bookmarkNotifier.toggle(paper)
                    : null,
                onOpen: hasFile
                    ? () => context.pushNamed(
                          AppRoutes.viewer,
                          queryParameters: {
                            'url':   paper.pdfUrl!,
                            'title': paper.title,
                          },
                        )
                    : null,
                onDownload: hasFile
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading "${paper.title}"…'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AppBarTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
