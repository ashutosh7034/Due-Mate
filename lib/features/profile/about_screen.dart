import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/seed_data.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../routes/app_routes.dart';

/// About, privacy summary and development utilities for DueMate.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.about),
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About DueMate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.lg,
          Spacing.xxxl,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadius.xlAll,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: scheme.onPrimary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(AppConstants.appName, style: AppTextStyles.headline),
                const SizedBox(height: Spacing.xs),
                Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          _Section(
            title: 'Privacy & Data Protection',
            body:
                'DueMate organizes your tasks securely under your account. '
                'Your tasks are isolated per user so only you can access your deadlines and reminders.',
          ),
          _Section(
            title: 'How reminders work',
            body:
                'Reminders are scheduled with your device\u2019s alarm service so '
                'they fire even when the app is closed. If your phone is '
                'restarted, they are restored automatically. When the system '
                'does not allow exact alarms, reminders are delivered as close '
                'to the time as the device permits.',
          ),
          if (kDebugMode) ...[
            const SizedBox(height: Spacing.xl),
            Text(
              'DEVELOPMENT',
              style: AppTextStyles.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'These tools are only visible in debug builds.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () => _addSampleData(context, ref),
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Add sample tasks'),
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton.icon(
              onPressed: () => _resetData(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Reset all data'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addSampleData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add sample tasks?'),
        content: const Text(
          'This adds a handful of development tasks, including one overdue '
          'and one recurring task.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final currentUser = ref.read(currentUserProvider);
    await SeedData.insert(
      taskRepo: ref.read(taskRepositoryProvider),
      categoryRepo: ref.read(categoryRepositoryProvider),
      userId: currentUser?.id ?? 'default_user',
    );
    await ref.read(reminderServiceProvider).processDueNotifications();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sample tasks added')));
    }
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently removes every task, reminder and category on this '
          'device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(databaseProvider).clearAllData();
    await ref
        .read(categoryRepositoryProvider)
        .seedDefaultsIfEmpty(DefaultCategories.build());
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All data reset')));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.sm),
          Text(body, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
