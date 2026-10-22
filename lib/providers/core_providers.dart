import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_service.dart';
import '../repositories/category_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/task_repository.dart';

/// The single database instance for the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.watch(databaseProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// Low-level platform notification wrapper.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

/// High-level reminder orchestration used by features.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    notifications: ref.watch(notificationServiceProvider),
    reminders: ref.watch(reminderRepositoryProvider),
    notificationCenter: ref.watch(notificationRepositoryProvider),
    tasks: ref.watch(taskRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// Live unread count for the notification-centre badge.
final unreadNotificationCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationRepositoryProvider).watchUnreadCount(),
);

/// Live notification-centre entries.
final notificationsProvider = StreamProvider((ref) {
  return ref.watch(notificationRepositoryProvider).watchAll();
});

/// Live notification permission status.
final notificationPermissionProvider =
    StreamProvider<NotificationPermissionStatus>((ref) async* {
      final service = ref.watch(notificationServiceProvider);
      yield service.permissions;
      yield* service.permissionStream;
    });
