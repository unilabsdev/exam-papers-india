import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: cs.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Exam Papers India',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Previous Year Question Papers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: cs.outlineVariant, height: 1),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Menu items ────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.download_done_rounded,
              label: 'Downloads',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/downloads');
              },
            ),

            _DrawerItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.of(context).pop();
                launchUrl(
                  Uri.parse('https://unilabsdev.github.io/exam-papers-privacy-policy/'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: cs.outlineVariant, height: 1),
            ),

            const SizedBox(height: 8),

            // ── Dark mode toggle ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) =>
                        ref.read(themeProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
