import 'package:flutter/material.dart';

/// Returns a user-friendly error message for any exception.
String friendlyError(Object err) {
  final raw = err.toString().toLowerCase();
  if (raw.contains('socket') ||
      raw.contains('host lookup') ||
      raw.contains('network') ||
      raw.contains('connection') ||
      raw.contains('timeout') ||
      raw.contains('clientexception')) {
    return 'No internet connection. Please check your network and try again.';
  }
  return 'Something went wrong. Please try again.';
}

/// Generic error state widget with an optional retry action.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: cs.error,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
