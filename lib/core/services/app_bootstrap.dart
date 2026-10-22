import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/settings_repository.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_service.dart';
import 'seed_data.dart';

/// Coordinating one-time startup work:
///  * initialise the notification plugin and timezone data,
///  * seed the default categories on first run,
///  * surface any reminders that elapsed while the app was closed.
///
/// Runs once; the UI shows a brief splash until it completes.
class AppBootstrap {
  const AppBootstrap({
    required this.categories,
    required this.settings,
    required this.notifications,
    required this.reminders,
  });

  final CategoryRepository categories;
  final SettingsRepository settings;
  final NotificationService notifications;
  final ReminderService reminders;

  Future<void> run() async {
    try {
      await notifications.initialize();
      await notifications.consumeLaunchTask();

      await categories.seedDefaultsIfEmpty(DefaultCategories.build());

      // Keep the optional daily summary in sync with the saved preference.
      await reminders.syncDailySummary(await settings.load());

      await reminders.processDueNotifications();
    } catch (e, s) {
      // Startup must never crash the app. Failures here degrade features
      // (e.g. notifications) rather than blocking the whole UI.
      if (kDebugMode) {
        debugPrint('[Bootstrap] startup step failed: $e\n$s');
      }
    }
  }
}

/// Builds the bootstrap from the Riverpod container. Kept as a provider so the
/// UI can await it and tests can override the repositories.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final bootstrap = AppBootstrap(
    categories: ref.read(categoryRepositoryProvider),
    settings: ref.read(settingsRepositoryProvider),
    notifications: ref.read(notificationServiceProvider),
    reminders: ref.read(reminderServiceProvider),
  );
  await bootstrap.run();
});
