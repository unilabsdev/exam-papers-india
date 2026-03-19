import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/year_model.dart';

/// Single row in the year list. Shows year, "Latest" badge, paper count.
class YearTile extends StatelessWidget {
  final YearModel year;
  final VoidCallback onTap;

  const YearTile({super.key, required this.year, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Year badge ──────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: year.isLatest
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    year.year.toString().substring(2), // "25" from 2025
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: year.isLatest
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Labels ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            year.year.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          if (year.isLatest) ...[
                            const SizedBox(width: 8),
                            const _Badge(
                              label: 'Latest',
                              color: AppColors.success,
                              bg: AppColors.successContainer,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${year.paperCount} papers available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Arrow ────────────────────────────────────────────────
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
