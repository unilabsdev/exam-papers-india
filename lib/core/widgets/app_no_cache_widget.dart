import 'package:flutter/material.dart';

/// Shown when the device is offline and no local cache exists yet.
/// Prompts the user to open the app once with internet to seed the cache.
class AppNoCacheWidget extends StatelessWidget {
  /// Optional — shown below the icon as context (e.g. 'years', 'papers').
  final String? dataLabel;

  const AppNoCacheWidget({super.key, this.dataLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = dataLabel != null ? '$dataLabel ' : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              'No Saved Data Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Open the app once with internet to enable offline access'
              '${label.isNotEmpty ? ' to ${label.trim()}' : ''}.',
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
