import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/category_model.dart';

/// Grid card for a single paper category.
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + arrow ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Category name ───────────────────────────────────────────
            Text(
              category.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // ── Description ─────────────────────────────────────────────
            Expanded(
              child: Text(
                category.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // ── Paper count pill (hidden for notification categories) ────
            if (!category.id.contains('notification'))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${category.paperCount} papers',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
