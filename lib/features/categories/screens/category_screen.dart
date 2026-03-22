import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_error_widget.dart' show AppErrorWidget, friendlyError;
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/widgets/app_no_cache_widget.dart';
import '../providers/category_provider.dart';
import '../widgets/category_card.dart';

class CategoryScreen extends ConsumerWidget {
  final String examId;
  final String examName;
  final int year;

  const CategoryScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.year,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(
      categoriesProvider(CategoryParams(examId: examId, year: year)),
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _AppBarTitle(examName: examName, subtitle: year.toString()),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
      ),
      body: categoriesAsync.when(
        loading: () =>
            const AppLoadingWidget(message: 'Loading categories…'),
        error: (err, _) => err is NoCacheException
            ? const AppNoCacheWidget(dataLabel: 'categories')
            : AppErrorWidget(
                message: friendlyError(err),
                onRetry: () => ref.invalidate(
                  categoriesProvider(CategoryParams(examId: examId, year: year)),
                ),
              ),
        data: (categories) {
          if (categories.isEmpty) {
            return const AppEmptyWidget(
              title: 'No Categories Found',
              subtitle: 'No paper categories are available for this exam.',
              icon: Icons.category_rounded,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  AppConstants.categoryGridCrossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio:
                  AppConstants.categoryCardAspectRatio,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return CategoryCard(
                category: cat,
                onTap: () => context.push(
                  Uri(
                    path:
                        '/exam/$examId/years/$year/categories/${cat.id}/papers',
                    queryParameters: {
                      'examName': examName,
                      'categoryName': cat.name,
                    },
                  ).toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final String examName;
  final String subtitle;

  const _AppBarTitle({required this.examName, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(examName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
