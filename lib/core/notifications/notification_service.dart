import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Our domain `Priority` enum collides with the notifications package's
// Android `Priority`, so the domain import is prefixed.
import '../../models/enums.dart' as domain;
import '../../models/task_item.dart';
import '../constants/app_constants.dart';
import 'notification_channels.dart';

// `Priority` below therefore always refers to the Android notification
// priority from `flutter_local_notifications`.
typedef DomainReminderKind = domain.ReminderKind;

enum ExactAlarmStatus { available, needsPermission, notRequired }

/// Comprehensive diagnostics for notifications and alarm scheduling.
class NotificationDiagnosticInfo {
  const NotificationDiagnosticInfo({
    required this.notificationsGranted,
    required this.exactAlarmsStatus,
    required this.channels,
    required this.pendingCount,
    required this.isSupported,
  });

  final bool notificationsGranted;
  final ExactAlarmStatus exactAlarmsStatus;
  final List<AndroidNotificationChannel> channels;
  final int pendingCount;
  final bool isSupported;
}

/// Current permission situation, surfaced to the UI so it can explain
/// limitations instead of silently failing.
class NotificationPermissionStatus {
  const NotificationPermissionStatus({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
    this.supported = true,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;
  final bool supported;

  bool get allGood => notificationsGranted && exactAlarmsGranted;

  static const NotificationPermissionStatus unsupported =
      NotificationPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
        supported: false,
      );
}

/// Tap payload attached to every notification so a tap can deep-link to a task.
class NotificationPayload {
  const NotificationPayload({required this.taskId, required this.kind});

  final String taskId;
  final String kind;

  String encode() => jsonEncode({'taskId': taskId, 'kind': kind});

  static NotificationPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final taskId = map['taskId'] as String?;
      if (taskId == null) return null;
      return NotificationPayload(
        taskId: taskId,
        kind: (map['kind'] as String?) ?? 'reminder',
      );
    } catch (_) {
      return null;
    }
  }
}

/// Wraps `flutter_local_notifications` behind a small, testable surface.
///
/// The service never touches the database; it only schedules/cancels OS
/// notifications. Keeping OS concerns isolated means the reminder rules can be
/// unit tested without a platform channel.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  final StreamController<NotificationPayload> _payloadController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<NotificationPermissionStatus>
  _permissionStreamController =
      StreamController<NotificationPermissionStatus>.broadcast();

  bool _initialized = false;
  bool _supported = true;
  NotificationPermissionStatus _permissions =
      NotificationPermissionStatus.unsupported;

  /// Emits a task id whenever the user taps a notification.
  Stream<String> get onNotificationTap => _tapController.stream;

  /// Emits full payload whenever a notification is tapped.
  Stream<NotificationPayload> get onNotificationPayload =>
      _payloadController.stream;

  /// Emits whenever permission status changes or is refreshed.
  Stream<NotificationPermissionStatus> get permissionStream =>
      _permissionStreamController.stream;

  NotificationPermissionStatus get permissions => _permissions;

  bool get isSupported => _supported;

  bool get isInitialized => _initialized;

  /// Whether OS-level scheduling is available on this platform.
  static bool get platformSupportsScheduling =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  /// One-time setup. Safe to call repeatedly.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _supported = false;
      _permissions = NotificationPermissionStatus.unsupported;
      _initialized = true;
      return;
    }

    try {
      tzdata.initializeTimeZones();
      await _configureLocalTimeZone();
    } catch (e, s) {
      // Timezone data is bundled with the app and should always load; if it
      // does not we still want the app usable, so fall back to UTC.
      _log('timezone init failed', e, s);
    }

    // Android requires a monochrome (white, transparent) status-bar icon; the
    // launcher icon would render as a solid blob. `ic_stat_deadline` is that
    // white silhouette.
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_deadline',
    );
    const darwinSettings = DarwinInitializationSettings(
      // Do not prompt on launch; we ask at the right moment from onboarding
      // or settings so the user understands why.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          // Tapping a notification opens its task. Action buttons carry the
          // same payload, so the same handler covers both.
          final payload = NotificationPayload.tryDecode(response.payload);
          if (payload != null) {
            _payloadController.add(payload);
            _tapController.add(payload.taskId);
          }
        },
      );
      _initialized = true;
      await _createChannels();
      await refreshPermissions();
    } catch (e, s) {
      _log('initialize failed', e, s);
      _supported = false;
      _permissions = NotificationPermissionStatus.unsupported;
      _initialized = true;
    }
  }

  /// Task id from a notification that launched the app from a cold start.
  ///
  /// Set once during [initialize]/bootstrap and cleared by [takeLaunchTask] so
  /// the UI deep-links exactly once.
  String? _launchTaskId;
  NotificationPayload? _launchPayload;

  String? get launchTaskId => _launchTaskId;
  NotificationPayload? get launchPayload => _launchPayload;

  /// Handles a cold start launched from a notification. Returns the task id
  /// and remembers it for [takeLaunchTask].
  Future<String?> consumeLaunchTask() async {
    if (!_supported) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = NotificationPayload.tryDecode(
          details?.notificationResponse?.payload,
        );
        _launchPayload = payload;
        _launchTaskId = payload?.taskId;
      }
    } catch (e, s) {
      _log('launch details failed', e, s);
    }
    return _launchTaskId;
  }

  /// Returns (and clears) the pending cold-start task id.
  String? takeLaunchTask() {
    final id = _launchTaskId;
    _launchTaskId = null;
    return id;
  }

  /// Returns (and clears) the pending cold-start payload.
  NotificationPayload? takeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    String identifier = 'UTC';
    try {
      identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] getLocalTimezone error: $e');
      }
    }
    try {
      tz.setLocalLocation(tz.getLocation(identifier));
    } catch (_) {
      try {
        final canonical = switch (identifier) {
          'Asia/Calcutta' => 'Asia/Kolkata',
          'Asia/Kolkata' => 'Asia/Calcutta',
          _ => null,
        };
        if (canonical != null) {
          tz.setLocalLocation(tz.getLocation(canonical));
          return;
        }
      } catch (_) {}
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _createChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final channel in NotificationChannels.all) {
      await android.createNotificationChannel(channel);
    }
  }

  /// Re-reads permission state from the OS.
  Future<NotificationPermissionStatus> refreshPermissions() async {
    if (kIsWeb || !_supported) {
      _permissions = NotificationPermissionStatus.unsupported;
      _permissionStreamController.add(_permissions);
      return _permissions;
    }
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled() ?? false;
        final canExact =
            await android?.canScheduleExactNotifications() ?? false;
        _permissions = NotificationPermissionStatus(
          notificationsGranted: enabled,
          exactAlarmsGranted: canExact,
        );
      } else {
        // On iOS/macOS the plugin does not expose a query; assume granted once
        // initialised (the OS silently drops notifications otherwise).
        _permissions = const NotificationPermissionStatus(
          notificationsGranted: true,
          exactAlarmsGranted: true,
        );
      }
    } catch (e, s) {
      _log('refreshPermissions failed', e, s);
    }
    _permissionStreamController.add(_permissions);
    return _permissions;
  }

  /// Requests notification + (optionally) exact-alarm permission.
  ///
  /// Returns the resulting status. Never throws — a denied permission is a
  /// normal outcome the UI explains.
  Future<NotificationPermissionStatus> requestPermissions({
    bool requestExactAlarms = true,
  }) async {
    if (kIsWeb || !_supported) return _permissions;
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
        if (requestExactAlarms) {
          final canExact =
              await android?.canScheduleExactNotifications() ?? false;
          if (!canExact) {
            await android?.requestExactAlarmsPermission();
          }
        }
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e, s) {
      _log('requestPermissions failed', e, s);
    }
    return refreshPermissions();
  }

  /// Opens the OS notification settings for this app.
  Future<void> openSystemSettings() async {
    if (kIsWeb || !_supported) return;
    try {
      await _plugin.openAppNotificationSettings();
    } catch (e, s) {
      _log('openAppNotificationSettings failed', e, s);
    }
  }

  // ---- Scheduling -------------------------------------------------------

  /// Schedules a single reminder. Silently no-ops when scheduling is
  /// unsupported or the time is in the past (a past-time schedule would throw).
  Future<bool> scheduleReminder({
    required TaskItem task,
    required int notificationId,
    required DateTime scheduledAt,
    required DomainReminderKind kind,
    String? titleOverride,
    String? bodyOverride,
    String channelId = NotificationChannels.taskRemindersId,
  }) async {
    if (!_supported || !platformSupportsScheduling) return false;

    await _configureLocalTimeZone();

    final local = scheduledAt.isUtc ? scheduledAt.toLocal() : scheduledAt;
    // Allow a small grace window; anything clearly in the past is skipped.
    if (local.isBefore(DateTime.now().subtract(const Duration(seconds: 5)))) {
      return false;
    }

    final scheduled = tz.TZDateTime.from(local, tz.local);
    final details = _detailsFor(kind, channelId, task: task);
    final body = bodyOverride ?? _bodyFor(task, kind);
    final title = titleOverride ?? _titleFor(task, kind);
    final mode = await _scheduleMode();

    final payloadKind = task.alarmType == domain.AlarmType.alarmScreen
        ? 'alarm'
        : kind.name;

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: NotificationPayload(
          taskId: task.id,
          kind: payloadKind,
        ).encode(),
      );
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Scheduled id $notificationId at $scheduled ($mode) for task ${task.id}',
        );
      }
      return true;
    } catch (e, s) {
      _log('scheduleReminder failed for ${task.id}', e, s);
      return false;
    }
  }

  Future<void> cancel(int notificationId) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e, s) {
      _log('cancel failed', e, s);
    }
  }

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (e, s) {
      _log('cancelAll failed', e, s);
    }
  }

  /// Schedules a repeating daily summary at [hour]:[minute] local time.
  Future<bool> scheduleDailySummary({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_supported || !platformSupportsScheduling) return false;
    await cancel(AppConstants.dailySummaryNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: AppConstants.dailySummaryNotificationId,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.dailySummaryId,
            'Daily summary',
            channelDescription: 'A quiet morning overview of what is due.',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
        androidScheduleMode: await _scheduleMode(),
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (e, s) {
      _log('scheduleDailySummary failed', e, s);
      return false;
    }
  }

  /// Shows a notification immediately (used for overdue nudges detected while
  /// the app is running, and for the in-app test button).
  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
    String? taskId,
    String channelId = NotificationChannels.overdueTasksId,
    bool highImportance = true,
    TaskItem? task,
  }) async {
    if (!_supported) return;
    final details = task != null
        ? _detailsFor(domain.ReminderKind.overdue, channelId, task: task)
        : NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              _channelName(channelId),
              channelDescription: _channelDescription(channelId),
              importance: highImportance
                  ? Importance.high
                  : Importance.defaultImportance,
              priority: highImportance
                  ? Priority.high
                  : Priority.defaultPriority,
              playSound: true,
              enableVibration: true,
              vibrationPattern:
                  channelId == NotificationChannels.deadlineAlertsId ||
                      channelId == NotificationChannels.overdueTasksId
                  ? NotificationChannels.urgentVibrationPattern
                  : NotificationChannels.standardVibrationPattern,
            ),
          );
    final payloadKind = task?.alarmType == domain.AlarmType.alarmScreen
        ? 'alarm'
        : 'overdue';
    try {
      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: taskId == null
            ? null
            : NotificationPayload(taskId: taskId, kind: payloadKind).encode(),
      );
    } catch (e, s) {
      _log('showNow failed', e, s);
    }
  }

  /// Sends an immediate test notification with sound and vibration configured.
  Future<bool> sendTestNotification() async {
    if (!_supported) return false;
    try {
      await showNow(
        notificationId: 999999,
        title: '🔔 DueMate: Test Reminder',
        body: 'Sound and vibration are configured and working properly.',
        channelId: NotificationChannels.taskRemindersId,
        highImportance: true,
      );
      return true;
    } catch (e, s) {
      _log('sendTestNotification failed', e, s);
      return false;
    }
  }

  /// Returns list of Android notification channels currently registered.
  Future<List<AndroidNotificationChannel>> getNotificationChannels() async {
    if (kIsWeb || !Platform.isAndroid || !_supported) return const [];
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return (await android?.getNotificationChannels()) ?? const [];
    } catch (e, s) {
      _log('getNotificationChannels failed', e, s);
      return const [];
    }
  }

  /// Returns all pending notification requests.
  Future<List<PendingNotificationRequest>>
  getPendingNotificationRequests() async {
    if (!_supported) return const [];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e, s) {
      _log('getPendingNotificationRequests failed', e, s);
      return const [];
    }
  }

  /// Gathers full diagnostic info for the Notification Diagnostics screen.
  Future<NotificationDiagnosticInfo> getDiagnostics() async {
    await refreshPermissions();
    final channels = await getNotificationChannels();
    final pending = await getPendingNotificationRequests();

    ExactAlarmStatus alarmStatus = ExactAlarmStatus.notRequired;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == null) {
        alarmStatus = ExactAlarmStatus.notRequired;
      } else if (canExact == true) {
        alarmStatus = ExactAlarmStatus.available;
      } else {
        alarmStatus = ExactAlarmStatus.needsPermission;
      }
    }

    return NotificationDiagnosticInfo(
      notificationsGranted: _permissions.notificationsGranted,
      exactAlarmsStatus: alarmStatus,
      channels: channels,
      pendingCount: pending.length,
      isSupported: _supported,
    );
  }

  /// Ids currently registered with the OS. Useful for diagnostics and for
  /// clearing orphaned alarms after a schema change.
  Future<List<int>> pendingIds() async {
    final pending = await getPendingNotificationRequests();
    return pending.map((p) => p.id).toList();
  }

  Future<void> dispose() async {
    await _tapController.close();
    await _permissionStreamController.close();
  }

  // ---- Internals --------------------------------------------------------

  /// Uses exact alarms when the OS allows them, otherwise falls back to an
  /// inexact but power-safe schedule. This is the honest handling of Android's
  /// exact-alarm restrictions — we degrade rather than pretend.
  Future<AndroidScheduleMode> _scheduleMode() async {
    if (kIsWeb || !Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  NotificationDetails _detailsFor(
    DomainReminderKind kind,
    String channelId, {
    TaskItem? task,
  }) {
    final isAlarmScreen = task?.alarmType == domain.AlarmType.alarmScreen;
    final isSoundVibration = task?.alarmType == domain.AlarmType.soundVibration;
    final isSilent =
        task?.soundChoice == domain.NotificationSound.silent &&
        task?.vibrationChoice == domain.NotificationVibration.silent;

    final String targetChannelId;
    if (isSilent) {
      targetChannelId = NotificationChannels.silentNotificationsId;
    } else if (isAlarmScreen || isSoundVibration) {
      targetChannelId = NotificationChannels.alarmSoundVibrationId;
    } else {
      targetChannelId = switch (kind) {
        domain.ReminderKind.atDeadline => NotificationChannels.deadlineAlertsId,
        domain.ReminderKind.overdue => NotificationChannels.overdueTasksId,
        domain.ReminderKind.beforeDeadline ||
        domain.ReminderKind.custom => NotificationChannels.taskRemindersId,
      };
    }

    final playSound = task?.soundChoice != domain.NotificationSound.silent;
    final enableVibration =
        task?.vibrationChoice != domain.NotificationVibration.silent;

    final Int64List vibration;
    if (task?.vibrationChoice == domain.NotificationVibration.continuous ||
        isAlarmScreen ||
        isSoundVibration) {
      vibration = NotificationChannels.continuousVibrationPattern;
    } else if (task?.vibrationChoice == domain.NotificationVibration.urgent ||
        kind == domain.ReminderKind.atDeadline ||
        kind == domain.ReminderKind.overdue) {
      vibration = NotificationChannels.urgentVibrationPattern;
    } else {
      vibration = NotificationChannels.standardVibrationPattern;
    }

    final importance = isSilent
        ? Importance.low
        : (isAlarmScreen || isSoundVibration)
        ? Importance.max
        : Importance.high;
    final priority = isSilent
        ? Priority.low
        : (isAlarmScreen || isSoundVibration)
        ? Priority.max
        : Priority.high;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        targetChannelId,
        _channelName(targetChannelId),
        channelDescription: _channelDescription(targetChannelId),
        importance: importance,
        priority: priority,
        playSound: playSound,
        enableVibration: enableVibration,
        vibrationPattern: vibration,
      ),
    );
  }

  String _titleFor(TaskItem task, domain.ReminderKind kind) {
    if (task.customNotificationTitle != null &&
        task.customNotificationTitle!.trim().isNotEmpty) {
      return task.customNotificationTitle!.trim();
    }
    switch (kind) {
      case domain.ReminderKind.atDeadline:
        return 'Due now: ${task.title}';
      case domain.ReminderKind.overdue:
        return '⚠️ Task overdue: ${task.title}';
      case domain.ReminderKind.custom:
      case domain.ReminderKind.beforeDeadline:
        return task.title;
    }
  }

  String _bodyFor(TaskItem task, domain.ReminderKind kind) {
    if (task.customNotificationBody != null &&
        task.customNotificationBody!.trim().isNotEmpty) {
      return task.customNotificationBody!.trim();
    }
    final deadline = task.deadline;
    final when = deadline == null ? null : _friendlyTime(deadline);
    switch (kind) {
      case domain.ReminderKind.atDeadline:
        return when == null ? 'Your deadline is now.' : 'Due $when.';
      case domain.ReminderKind.overdue:
        return when == null
            ? 'This task has passed its deadline.'
            : '${task.title} was due $when.';
      case domain.ReminderKind.custom:
      case domain.ReminderKind.beforeDeadline:
        return when == null ? 'A quick reminder for this task.' : 'Due $when.';
    }
  }

  String _friendlyTime(DateTime deadline) {
    final local = deadline.isUtc ? deadline.toLocal() : deadline;
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return sameDay ? 'today at $h:$m $ampm' : 'on ${local.day}/${local.month}';
  }

  String _channelName(String id) => switch (id) {
    NotificationChannels.deadlineAlertsId => 'Deadline alerts',
    NotificationChannels.overdueTasksId => 'Overdue tasks',
    NotificationChannels.dailySummaryId => 'Daily summary',
    NotificationChannels.alarmSoundVibrationId => 'Sound & vibration alarms',
    NotificationChannels.silentNotificationsId => 'Silent notifications',
    _ => 'Task reminders',
  };

  String _channelDescription(String id) => switch (id) {
    NotificationChannels.deadlineAlertsId =>
      'Fires at the exact moment a task is due.',
    NotificationChannels.overdueTasksId =>
      'A single nudge when a task has passed its deadline.',
    NotificationChannels.dailySummaryId =>
      'A quiet morning overview of what is due.',
    NotificationChannels.alarmSoundVibrationId =>
      'High-urgency repeating alarms for tasks and deadlines.',
    NotificationChannels.silentNotificationsId =>
      'Quiet notifications without sound or vibration.',
    _ => 'Reminders you set ahead of a deadline.',
  };

  /// Generates a notification id in the range Android accepts (positive
  /// 32-bit int), avoiding [taken].
  static int allocateNotificationId(Set<int> taken) {
    final random = Random();
    const min = 1000;
    const max = 0x7FFFFFFF;
    for (var i = 0; i < 64; i++) {
      final candidate = min + random.nextInt(max - min);
      if (!taken.contains(candidate)) return candidate;
    }
    // Deterministic fallback if we somehow collide 64 times.
    var candidate = min;
    while (taken.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  void _log(String message, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[NotificationService] $message: $error');
      // ignore: avoid_print
      print('[NotificationService] $message: $error');
    }
  }
}
