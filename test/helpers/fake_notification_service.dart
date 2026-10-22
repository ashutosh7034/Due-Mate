import 'package:duemate/core/notifications/notification_service.dart';
import 'package:duemate/models/task_item.dart';

/// A [NotificationService] that records calls instead of touching the platform.
///
/// Used by controller/integration tests to assert scheduling behaviour
/// (scenarios 4–7) without a device.
class FakeNotificationService extends NotificationService {
  FakeNotificationService();

  final List<ScheduledCall> scheduled = [];
  final List<int> cancelled = [];
  final List<int> shownNow = [];
  int cancelAllCount = 0;
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> scheduleReminder({
    required TaskItem task,
    required int notificationId,
    required DateTime scheduledAt,
    required DomainReminderKind kind,
    String? titleOverride,
    String? bodyOverride,
    String channelId = 'task_reminders_v2',
  }) async {
    scheduled.add(
      ScheduledCall(
        taskId: task.id,
        notificationId: notificationId,
        scheduledAt: scheduledAt,
        kind: kind,
      ),
    );
    return true;
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelMany(Iterable<int> ids) async {
    cancelled.addAll(ids);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }

  @override
  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
    String? taskId,
    String channelId = 'overdue_tasks_v2',
    bool highImportance = true,
    TaskItem? task,
  }) async {
    shownNow.add(notificationId);
  }

  @override
  Future<bool> sendTestNotification() async {
    await showNow(
      notificationId: 999999,
      title: '🔔 DueMate: Test Reminder',
      body: 'Sound and vibration test',
      channelId: 'task_reminders_v2',
    );
    return true;
  }

  @override
  Future<NotificationDiagnosticInfo> getDiagnostics() async {
    return const NotificationDiagnosticInfo(
      notificationsGranted: true,
      exactAlarmsStatus: ExactAlarmStatus.available,
      channels: [],
      pendingCount: 0,
      isSupported: true,
    );
  }

  @override
  Future<NotificationPermissionStatus> refreshPermissions() async {
    return const NotificationPermissionStatus(
      notificationsGranted: true,
      exactAlarmsGranted: true,
    );
  }

  @override
  Future<NotificationPermissionStatus> requestPermissions({
    bool requestExactAlarms = true,
  }) async {
    return refreshPermissions();
  }

  @override
  Future<void> dispose() async {}

  /// Scheduled calls for one task.
  List<ScheduledCall> forTask(String taskId) =>
      scheduled.where((c) => c.taskId == taskId).toList();
}

class ScheduledCall {
  ScheduledCall({
    required this.taskId,
    required this.notificationId,
    required this.scheduledAt,
    required this.kind,
  });

  final String taskId;
  final int notificationId;
  final DateTime scheduledAt;
  final DomainReminderKind kind;

  @override
  String toString() =>
      'ScheduledCall(task: $taskId, id: $notificationId, at: $scheduledAt, kind: ${kind.name})';
}
