import 'package:duemate/core/notifications/notification_channels.dart';
import 'package:duemate/core/notifications/notification_permission_coordinator.dart';
import 'package:duemate/core/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Channels Configuration', () {
    test(
      'Channels use _v2 identifiers to avoid cached silent channel properties',
      () {
        expect(
          NotificationChannels.deadlineAlertsId,
          equals('deadline_alerts_v2'),
        );
        expect(
          NotificationChannels.taskRemindersId,
          equals('task_reminders_v2'),
        );
        expect(NotificationChannels.overdueTasksId, equals('overdue_tasks_v2'));
        expect(NotificationChannels.dailySummaryId, equals('daily_summary_v2'));
      },
    );

    test('Critical reminder channels have High importance, sound and vibration enabled', () {
      final deadline = NotificationChannels.deadlineAlerts;
      expect(deadline.importance, equals(Importance.high));
      expect(deadline.playSound, isTrue);
      expect(deadline.enableVibration, isTrue);
      expect(deadline.vibrationPattern, isNotNull);

      final reminders = NotificationChannels.taskReminders;
      expect(reminders.importance, equals(Importance.high));
      expect(reminders.playSound, isTrue);
      expect(reminders.enableVibration, isTrue);
      expect(reminders.vibrationPattern, isNotNull);

      final overdue = NotificationChannels.overdueTasks;
      expect(overdue.importance, equals(Importance.high));
      expect(overdue.playSound, isTrue);
      expect(overdue.enableVibration, isTrue);
      expect(overdue.vibrationPattern, isNotNull);
    });

    test('Daily summary channel has Low importance to remain unobtrusive', () {
      final summary = NotificationChannels.dailySummary;
      expect(summary.importance, equals(Importance.low));
      expect(summary.playSound, isFalse);
      expect(summary.enableVibration, isFalse);
    });
  });

  group('Notification Permission Coordinator & Preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasShownExplanation starts as false on fresh install', () async {
      final shown =
          await NotificationPermissionCoordinator.hasShownExplanation();
      expect(shown, isFalse);
    });

    test(
      'markExplanationShown persists true and prevents repeated dialogs',
      () async {
        await NotificationPermissionCoordinator.markExplanationShown();
        final shown =
            await NotificationPermissionCoordinator.hasShownExplanation();
        expect(shown, isTrue);
      },
    );

    test('wasPreviouslyDenied tracks user denial accurately', () async {
      expect(
        await NotificationPermissionCoordinator.wasPreviouslyDenied(),
        isFalse,
      );
      await NotificationPermissionCoordinator.setPreviouslyDenied(true);
      expect(
        await NotificationPermissionCoordinator.wasPreviouslyDenied(),
        isTrue,
      );
      await NotificationPermissionCoordinator.setPreviouslyDenied(false);
      expect(
        await NotificationPermissionCoordinator.wasPreviouslyDenied(),
        isFalse,
      );
    });
  });

  group('Notification Diagnostics Model', () {
    test(
      'NotificationDiagnosticInfo instantiates and reports status correctly',
      () {
        const info = NotificationDiagnosticInfo(
          notificationsGranted: true,
          exactAlarmsStatus: ExactAlarmStatus.available,
          channels: [],
          pendingCount: 3,
          isSupported: true,
        );

        expect(info.notificationsGranted, isTrue);
        expect(info.exactAlarmsStatus, equals(ExactAlarmStatus.available));
        expect(info.pendingCount, equals(3));
        expect(info.isSupported, isTrue);
      },
    );

    test('NotificationPermissionStatus allGood requires both notifications and exact alarms', () {
      const both = NotificationPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: true,
      );
      expect(both.allGood, isTrue);

      const notifsOnly = NotificationPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: false,
      );
      expect(notifsOnly.allGood, isFalse);

      const neither = NotificationPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
      expect(neither.allGood, isFalse);
    });
  });

  group('Notification ID Allocation', () {
    test('allocateNotificationId produces unique 32-bit positive integer', () {
      final taken = <int>{};
      for (var i = 0; i < 50; i++) {
        final id = NotificationService.allocateNotificationId(taken);
        expect(taken.contains(id), isFalse);
        expect(id, greaterThan(0));
        taken.add(id);
      }
      expect(taken.length, equals(50));
    });
  });

  group('Notification Payload Serialization', () {
    test('encodes and decodes taskId and kind reliably', () {
      const payload = NotificationPayload(
        taskId: 'task-123',
        kind: 'atDeadline',
      );
      final encoded = payload.encode();
      final decoded = NotificationPayload.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.taskId, equals('task-123'));
      expect(decoded.kind, equals('atDeadline'));
    });

    test('tryDecode handles malformed and empty strings gracefully', () {
      expect(NotificationPayload.tryDecode(null), isNull);
      expect(NotificationPayload.tryDecode(''), isNull);
      expect(NotificationPayload.tryDecode('not-a-json'), isNull);
      expect(NotificationPayload.tryDecode('{"other":"value"}'), isNull);
    });
  });
}
