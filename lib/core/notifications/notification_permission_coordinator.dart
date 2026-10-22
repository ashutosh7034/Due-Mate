import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import 'notification_service.dart';

/// Coordinates first-launch notification onboarding, persistent explanation tracking,
/// graceful permission fallbacks, and Android settings navigation.
class NotificationPermissionCoordinator {
  const NotificationPermissionCoordinator._();

  static const String prefKeyExplanationShown =
      'duemate_notification_explanation_shown';
  static const String prefKeyPreviouslyDenied =
      'duemate_notification_previously_denied';

  /// Whether the app has already displayed its first-launch explanation.
  static Future<bool> hasShownExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyExplanationShown) ?? false;
  }

  /// Records that the first-launch explanation has been shown.
  static Future<void> markExplanationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyExplanationShown, true);
  }

  /// Whether the user previously denied notification permissions.
  static Future<bool> wasPreviouslyDenied() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyPreviouslyDenied) ?? false;
  }

  /// Sets whether notifications were denied.
  static Future<void> setPreviouslyDenied(bool denied) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyPreviouslyDenied, denied);
  }

  /// Checks if the first-launch onboarding explanation needs to be displayed,
  /// and presents it if not already shown.
  static Future<void> checkAndPromptFirstLaunch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!NotificationService.platformSupportsScheduling) return;

    final shown = await hasShownExplanation();
    if (shown) return;

    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    final status = await service.refreshPermissions();

    // If notifications are already granted by the system, mark shown and exit.
    if (status.notificationsGranted) {
      await markExplanationShown();
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: scheme.primary,
              size: 28,
            ),
          ),
          title: Text(
            'Stay on top of deadlines',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline,
          ),
          content: Text(
            'Allow notifications so DueMate can remind you about tasks and deadlines.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await markExplanationShown();
                await setPreviouslyDenied(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications disabled. You can enable them anytime in Settings.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await markExplanationShown();
                final result = await service.requestPermissions();
                if (result.notificationsGranted) {
                  await setPreviouslyDenied(false);
                  await ref
                      .read(settingsControllerProvider)
                      .setNotificationsEnabled(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications enabled! Reminders and deadline alerts are active.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  await setPreviouslyDenied(true);
                  // Do not falsely mark notifications as enabled when permission is denied.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Permission was not granted. You can enable reminders later in Settings.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('Allow notifications'),
            ),
          ],
        );
      },
    );
  }

  /// Handles explicit user opt-in from Settings or feature switches.
  /// If previously denied or permanently blocked by Android, offers to open Android Settings.
  static Future<bool> requestWithOptInFlow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    var status = await service.refreshPermissions();

    if (status.notificationsGranted) {
      await setPreviouslyDenied(false);
      await ref.read(settingsControllerProvider).setNotificationsEnabled(true);
      return true;
    }

    final previouslyDenied = await wasPreviouslyDenied();

    // Attempt system permission request first.
    status = await service.requestPermissions();
    if (status.notificationsGranted) {
      await setPreviouslyDenied(false);
      await ref.read(settingsControllerProvider).setNotificationsEnabled(true);
      return true;
    }

    // Permission was denied or permanently blocked. Provide explanation and Settings navigation.
    await setPreviouslyDenied(true);
    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            Icons.notifications_off_outlined,
            color: scheme.error,
            size: 32,
          ),
          title: Text(
            previouslyDenied
                ? 'Enable notifications in Settings'
                : 'Notification permission needed',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline,
          ),
          content: Text(
            'Notifications are blocked on your device. To receive reminders and deadline alerts with sound and vibration, please allow notifications for DueMate in Android Settings.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await service.openSystemSettings();
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    return false;
  }
}
