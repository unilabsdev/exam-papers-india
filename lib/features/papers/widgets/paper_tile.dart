import 'package:flutter/material.dart';

import '../../../models/paper_model.dart';

/// Card for a single question paper — shows metadata chips + bookmark + Open/Download CTA.
class PaperTile extends StatelessWidget {
  final PaperModel paper;
  final bool isBookmarked;
  final bool isFileAvailable;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback? onBookmarkToggle;

  const PaperTile({
    super.key,
    required this.paper,
    this.isBookmarked = false,
    this.isFileAvailable = true,
    this.onOpen,
    this.onDownload,
    this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
            // ── Header row ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: cs.primary,
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

                // Bookmark toggle button
                IconButton(
                  onPressed: isFileAvailable ? onBookmarkToggle : null,
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFileAvailable
                        ? (isBookmarked ? cs.primary : cs.onSurfaceVariant)
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Metadata chips ──────────────────────────────────────────
            if (!isFileAvailable)
              _Chip(
                icon: Icons.cloud_off_rounded,
                label: 'File not available',
                color: cs.error.withValues(alpha: 0.12),
                iconColor: cs.error,
                labelColor: cs.error,
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

            // ── Action buttons ──────────────────────────────────────────
            Row(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal metadata chip ──────────────────────────────────────────────────
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
