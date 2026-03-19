import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_router.dart';
import '../providers/download_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme     = Theme.of(context);
    final cs        = theme.colorScheme;
    // Watch map so screen rebuilds when downloads change
    ref.watch(downloadProvider);
    final downloads = ref.read(downloadProvider.notifier).allDownloads;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const _AppBarTitle(),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              onPressed: () => _confirmClearAll(context, ref),
              icon: Icon(Icons.delete_sweep_rounded,
                  color: cs.error.withValues(alpha: 0.8)),
              tooltip: 'Clear all downloads',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: downloads.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.only(top: 12, bottom: 32),
              itemCount: downloads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final record = downloads[index];
                return _DownloadTile(
                  record: record,
                  onOpen: () => context.pushNamed(
                    AppRoutes.viewer,
                    queryParameters: {
                      'url':       record.pdfUrl,
                      'title':     record.title,
                      'localPath': record.localPath,
                    },
                  ),
                  onDelete: () =>
                      _confirmDelete(context, ref, record.id, record.title),
                );
              },
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String title) {
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
              ref.read(downloadProvider.notifier).deleteDownload(id);
            },
            child: Text('Remove',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content:
            const Text('Remove all downloaded papers from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(downloadProvider.notifier);
              final all = List.of(notifier.allDownloads);
              for (final r in all) {
                await notifier.deleteDownload(r.id);
              }
            },
            child: Text('Clear All',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── App bar title ──────────────────────────────────────────────────────────────

class _AppBarTitle extends ConsumerWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadProvider);
    final count = ref.read(downloadProvider.notifier).allDownloads.length;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Downloads',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        if (count > 0)
          Text(
            '$count paper${count == 1 ? '' : 's'} saved',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.download_done_rounded,
                  size: 40, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text('No Downloads Yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'Papers you download will appear here.\nOpen a paper and tap Download.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Download tile ──────────────────────────────────────────────────────────────

class _DownloadTile extends StatelessWidget {
  final DownloadedPaperRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DownloadTile({
    required this.record,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded,
                      color: cs.primary, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${record.categoryName} · ${record.year}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: cs.error.withValues(alpha: 0.7), size: 20),
                  tooltip: 'Remove download',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Chips row ─────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(context, Icons.offline_pin_rounded, 'Saved offline',
                    cs.primaryContainer, cs.primary),
                _chip(context, Icons.calendar_today_rounded,
                    _formatDate(record.downloadedAt),
                    cs.surfaceContainerHighest, cs.onSurfaceVariant),
              ],
            ),

            const SizedBox(height: 14),

            // ── Read button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Read Offline'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  Widget _chip(BuildContext context, IconData icon, String label,
      Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
