import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_error_widget.dart' show AppErrorWidget, friendlyError;
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/review_service.dart';
import '../../downloads/providers/download_provider.dart';
import '../providers/paper_provider.dart';
import '../repositories/paper_repository.dart';
import '../widgets/paper_tile.dart';

class PapersScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends ConsumerState<PapersScreen> {
  bool _showDownloadedOnly = false;

  @override
  Widget build(BuildContext context) {
    final params = PaperParams(
      examId:     widget.examId,
      year:       widget.year,
      categoryId: widget.categoryId,
    );
    final papersAsync      = ref.watch(papersProvider(params));
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final downloadStates   = ref.watch(downloadProvider);
    final theme            = Theme.of(context);

    ref.listen(downloadProvider, (prev, next) {
      for (final entry in next.entries) {
        if (entry.value.status == DownloadStatus.failed) {
          final prevStatus = prev?[entry.key]?.status;
          if (prevStatus == DownloadStatus.downloading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _AppBarTitle(
          title:    widget.categoryName,
          subtitle: '${widget.examName} · ${widget.year}',
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context, downloadStates),
            icon: Icon(
              Icons.filter_list_rounded,
              color: _showDownloadedOnly
                  ? theme.colorScheme.primary
                  : null,
            ),
            tooltip: 'Filter',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: papersAsync.when(
        loading: () => const AppLoadingWidget(message: 'Loading papers…'),
        error: (err, _) => AppErrorWidget(
          message: friendlyError(err),
          onRetry: () => ref.invalidate(papersProvider(params)),
        ),
        data: (papers) {
          final filtered = _showDownloadedOnly
              ? papers.where((p) =>
                  downloadStates[p.id]?.status == DownloadStatus.downloaded)
                  .toList()
              : papers;

          if (filtered.isEmpty) {
            return AppEmptyWidget(
              title: _showDownloadedOnly
                  ? 'No Downloaded Papers'
                  : 'No Papers Found',
              subtitle: _showDownloadedOnly
                  ? 'Download papers to read them offline.'
                  : 'No question papers are available for this selection.',
              icon: Icons.description_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final paper        = filtered[index];
              final hasFile      = paper.pdfUrl != null && paper.pdfUrl!.isNotEmpty;
              final dlState      = downloadStates[paper.id] ?? const DownloadState();
              final isDownloaded = dlState.status == DownloadStatus.downloaded;

              return PaperTile(
                paper:           paper,
                downloadState:   dlState,
                isFileAvailable: hasFile,

                onOpen: hasFile
                    ? () {
                        ReviewService.onPaperOpened();
                        AdService.showInterstitial(onDone: () {
                          if (context.mounted) {
                            context.pushNamed(
                              AppRoutes.viewer,
                              queryParameters: {
                                'url':          paper.pdfUrl!,
                                'title':        paper.title,
                                'paperId':      paper.id,
                                'examId':       paper.examId,
                                'examName':     widget.examName,
                                'year':         paper.year.toString(),
                                'categoryId':   paper.categoryId,
                                'categoryName': paper.categoryName,
                              },
                            );
                          }
                        });
                      }
                    : null,

                onDownload: hasFile
                    ? () => downloadNotifier.download(paper)
                    : null,

                onRead: isDownloaded
                    ? () {
                        ReviewService.onPaperOpened();
                        AdService.showInterstitial(onDone: () {
                          if (context.mounted) {
                            context.pushNamed(
                              AppRoutes.viewer,
                              queryParameters: {
                                'url':       paper.pdfUrl ?? '',
                                'title':     paper.title,
                                'localPath': dlState.localPath ?? '',
                              },
                            );
                          }
                        });
                      }
                    : null,

                onDelete: isDownloaded
                    ? () => _confirmDelete(context, paper.id, paper.title)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, Map<String, DownloadState> downloadStates) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Papers',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Downloaded only'),
                subtitle: const Text('Show only papers saved offline'),
                value: _showDownloadedOnly,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setSheetState(() {});
                  setState(() => _showDownloadedOnly = val);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String paperId, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Download'),
        content: Text('Remove "$title" from downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(downloadProvider.notifier).deleteDownload(paperId);
            },
            child: Text('Remove',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
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
