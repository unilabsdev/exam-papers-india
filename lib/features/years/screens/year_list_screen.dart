import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_empty_widget.dart';
import '../../../core/widgets/app_error_widget.dart' show AppErrorWidget, friendlyError;
import '../../../core/widgets/app_loading_widget.dart';
import '../providers/year_provider.dart';
import '../widgets/year_tile.dart';

class YearListScreen extends ConsumerWidget {
  final String examId;
  final String examName;

  const YearListScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(yearsProvider(examId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _AppBarTitle(examName: examName, subtitle: 'Select Year'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
      ),
      body: yearsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Loading years…'),
        error: (err, _) => AppErrorWidget(
          message: friendlyError(err),
          onRetry: () => ref.invalidate(yearsProvider(examId)),
        ),
        data: (years) {
          if (years.isEmpty) {
            return const AppEmptyWidget(
              title: 'No Years Found',
              subtitle: 'No papers available for this exam yet.',
              icon: Icons.calendar_today_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: years.length,
            itemBuilder: (context, index) => YearTile(
              year: years[index],
              onTap: () => context.push(
                Uri(
                  path:
                      '/exam/$examId/years/${years[index].year}/categories',
                  queryParameters: {'examName': examName},
                ).toString(),
              ),
            ),
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
