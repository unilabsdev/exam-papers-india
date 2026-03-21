import 'package:flutter/material.dart';

import '../../../features/downloads/providers/download_provider.dart';
import '../../../models/paper_model.dart';

/// Card for a single question paper.
/// Shows three states based on [downloadState]:
///   • notDownloaded  → "Open Online" + "Download" buttons
///   • downloading    → animated progress bar with percentage
///   • downloaded     → "Read" button + delete icon
class PaperTile extends StatelessWidget {
  final PaperModel paper;
  final bool isFileAvailable;
  final DownloadState downloadState;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback? onRead;
  final VoidCallback? onDelete;

  const PaperTile({
    super.key,
    required this.paper,
    required this.downloadState,
    this.isFileAvailable = true,
    this.onOpen,
    this.onDownload,
    this.onRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final cs         = theme.colorScheme;
    final isDownloaded = downloadState.status == DownloadStatus.downloaded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
            // ── Header row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDownloaded
                        ? Icons.check_circle_rounded
                        : Icons.picture_as_pdf_rounded,
                    color: isDownloaded ? cs.primary : cs.onSurfaceVariant,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Title + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paper.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        paper.categoryName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete icon (downloaded only)
                if (isDownloaded)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error.withValues(alpha: 0.7)),
                    tooltip: 'Remove download',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  )
              ],
            ),

            const SizedBox(height: 12),

            // ── Metadata chips ────────────────────────────────────────────
            if (!isFileAvailable)
              _Chip(
                icon: Icons.cloud_off_rounded,
                label: 'File not available',
                color: cs.error.withValues(alpha: 0.12),
                iconColor: cs.error,
                labelColor: cs.error,
              )
            else if (isDownloaded)
              _Chip(
                icon: Icons.offline_pin_rounded,
                label: 'Downloaded',
                color: cs.primaryContainer,
                iconColor: cs.primary,
                labelColor: cs.primary,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (paper.totalQuestions != null)
                    _Chip(
                      icon: Icons.help_outline_rounded,
                      label: '${paper.totalQuestions} Qs',
                    ),
                  if (paper.totalMarks != null)
                    _Chip(
                      icon: Icons.stars_rounded,
                      label: '${paper.totalMarks} Marks',
                    ),
                  if (paper.durationMinutes != null)
                    _Chip(
                      icon: Icons.timer_outlined,
                      label: '${paper.durationMinutes} Min',
                    ),
                  if (paper.fileSizeMb != null)
                    _Chip(
                      icon: Icons.storage_rounded,
                      label: '${paper.fileSizeMb!.toStringAsFixed(1)} MB',
                    ),
                  if (paper.language != null)
                    _Chip(
                      icon: Icons.language_rounded,
                      label: paper.language!,
                    ),
                ],
              ),

            const SizedBox(height: 14),

            // ── Action area ───────────────────────────────────────────────
            _buildActions(context, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme cs) {
    switch (downloadState.status) {
      // ── Downloaded: Read + inline delete hint ──────────────────────────
      case DownloadStatus.downloaded:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: const Text('Read Offline'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      // ── Downloading: animated progress bar ────────────────────────────
      case DownloadStatus.downloading:
        final pct = (downloadState.progress * 100).toStringAsFixed(0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading…',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: downloadState.progress),
                duration: const Duration(milliseconds: 200),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ),
          ],
        );

      // ── Failed: show retry option ──────────────────────────────────────
      case DownloadStatus.failed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        );

      // ── Not downloaded: Open Online + Download ─────────────────────────
      case DownloadStatus.notDownloaded:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ── Internal metadata chip ─────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? iconColor;
  final Color? labelColor;

  const _Chip({
    required this.icon,
    required this.label,
    this.color,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor ?? cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
