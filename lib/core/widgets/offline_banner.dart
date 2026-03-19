import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';

/// Wraps any [child] with a persistent top banner shown when offline.
class OfflineBanner extends ConsumerWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isOffline
              ? Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Theme.of(context).colorScheme.onError,
                          size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'You\'re offline — some content may not load',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onError),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
