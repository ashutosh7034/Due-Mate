import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channels.
///
/// Configured with high importance, audible alerts, and distinct vibration
/// patterns so task deadlines and reminders reliably alert the user.
class NotificationChannels {
  const NotificationChannels._();

  static const String deadlineAlertsId = 'deadline_alerts_v2';
  static const String taskRemindersId = 'task_reminders_v2';
  static const String overdueTasksId = 'overdue_tasks_v2';
  static const String dailySummaryId = 'daily_summary_v2';
  static const String alarmSoundVibrationId = 'alarm_sound_vibration_v3';
  static const String silentNotificationsId = 'silent_notifications_v3';

  /// Distinct vibration pattern for urgent deadline alerts: pause 0, vibe 350, pause 150, vibe 350.
  static final Int64List urgentVibrationPattern = Int64List.fromList([
    0,
    350,
    150,
    350,
  ]);

  /// Standard vibration pattern for task reminders: pause 0, vibe 250, pause 200, vibe 250.
  static final Int64List standardVibrationPattern = Int64List.fromList([
    0,
    250,
    200,
    250,
  ]);

  /// Continuous alert vibration pattern: pause 0, vibe 500, pause 200, vibe 500, pause 200, vibe 500.
  static final Int64List continuousVibrationPattern = Int64List.fromList([
    0,
    500,
    200,
    500,
    200,
    500,
  ]);

  static final AndroidNotificationChannel deadlineAlerts =
      AndroidNotificationChannel(
        deadlineAlertsId,
        'Deadline alerts',
        description: 'Fires at the exact moment a task is due.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: urgentVibrationPattern,
        enableLights: true,
      );

  static final AndroidNotificationChannel taskReminders =
      AndroidNotificationChannel(
        taskRemindersId,
        'Task reminders',
        description: 'Reminders you set ahead of a deadline.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: standardVibrationPattern,
        enableLights: true,
      );

  static final AndroidNotificationChannel overdueTasks =
      AndroidNotificationChannel(
        overdueTasksId,
        'Overdue tasks',
        description: 'A single nudge when a task has passed its deadline.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: urgentVibrationPattern,
        enableLights: true,
      );

  static const AndroidNotificationChannel dailySummary =
      AndroidNotificationChannel(
        dailySummaryId,
        'Daily summary',
        description: 'A quiet morning overview of what is due.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  static final AndroidNotificationChannel alarmSoundVibration =
      AndroidNotificationChannel(
        alarmSoundVibrationId,
        'Sound & vibration alarms',
        description: 'High-urgency repeating alarms for tasks and deadlines.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: continuousVibrationPattern,
        enableLights: true,
      );

  static const AndroidNotificationChannel silentNotifications =
      AndroidNotificationChannel(
        silentNotificationsId,
        'Silent notifications',
        description: 'Quiet notifications without sound or vibration.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  static final List<AndroidNotificationChannel> all = [
    deadlineAlerts,
    taskReminders,
    overdueTasks,
    dailySummary,
    alarmSoundVibration,
    silentNotifications,
  ];
}
