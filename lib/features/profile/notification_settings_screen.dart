import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_permission_coordinator.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/user_settings.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_routes.dart';
import 'notification_diagnostics_screen.dart';

/// Notification preferences, including permission state and busy hours.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.notificationSettings),
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
  }

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  NotificationPermissionStatus? _permission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermission();
    }
  }

  Future<void> _refreshPermission() async {
    final service = ref.read(notificationServiceProvider);
    final status = await service.refreshPermissions();
    if (mounted) setState(() => _permission = status);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();
    final controller = ref.read(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final permission = _permission;
    final effectiveEnabled =
        settings.notificationsEnabled &&
        (permission?.notificationsGranted ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xxxl,
        ),
        children: [
          if (permission != null && permission.supported)
            _PermissionBanner(
              status: permission,
              onEnable: _requestPermissions,
              onOpenSettings: () =>
                  ref.read(notificationServiceProvider).openSystemSettings(),
            ),
          const SizedBox(height: Spacing.sm),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.troubleshoot_rounded, color: scheme.primary),
            title: Text('Notification Diagnostics', style: AppTextStyles.body),
            subtitle: Text(
              'Inspect Android channels, test delivery, and verify alarms.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => NotificationDiagnosticsScreen.open(context),
          ),
          const Divider(),

          SwitchListTile(
            value: effectiveEnabled,
            onChanged: (value) async {
              if (value) {
                final granted =
                    await NotificationPermissionCoordinator.requestWithOptInFlow(
                      context,
                      ref,
                    );
                if (granted) {
                  await controller.setNotificationsEnabled(true);
                  await _refreshPermission();
                }
              } else {
                await controller.setNotificationsEnabled(false);
                await _refreshPermission();
              }
            },
            title: Text('Enable notifications', style: AppTextStyles.body),
            subtitle: Text(
              'Master switch for every reminder.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            value: settings.upcomingAlertsEnabled,
            onChanged: settings.notificationsEnabled
                ? controller.setUpcomingAlerts
                : null,
            title: Text('Upcoming deadline alerts', style: AppTextStyles.body),
            subtitle: Text(
              'A heads-up shortly before a deadline.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: settings.overdueRemindersEnabled,
            onChanged: settings.notificationsEnabled
                ? controller.setOverdueReminders
                : null,
            title: Text('Overdue reminders', style: AppTextStyles.body),
            subtitle: Text(
              'A single nudge when a task passes its deadline.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: settings.dailySummaryEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) async {
                    await controller.setDailySummary(value);
                    await _applyDailySummary();
                  }
                : null,
            title: Text('Daily summary', style: AppTextStyles.body),
            subtitle: Text(
              'One quiet morning overview at 8:00 AM.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: Spacing.lg),

          Text(
            'DEFAULT REMINDER',
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Applied to new tasks unless you change it.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final preset in ReminderPresets.standard)
                if (preset.minutesBefore != null)
                  ChoiceChip(
                    label: Text(preset.label),
                    selected:
                        settings.defaultReminderMinutes == preset.minutesBefore,
                    onSelected: settings.notificationsEnabled
                        ? (_) => controller.setDefaultReminderMinutes(
                            preset.minutesBefore!,
                          )
                        : null,
                  ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),

          Text(
            'DEFAULT ALARMS & PERSISTENT REMINDERS',
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Applied to newly created tasks. Can be customized per task.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Default Alarm Type
          Text('DEFAULT ALERT TYPE', style: AppTextStyles.label),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.sm,
            children: AlarmType.values.map((type) {
              final selected = settings.defaultAlarmType == type.name;
              return ChoiceChip(
                avatar: Icon(type.icon, size: 16),
                label: Text(type.label),
                selected: selected,
                onSelected: settings.notificationsEnabled
                    ? (_) => controller.setDefaultAlarmType(type.name)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.lg),

          // Default Repeat until completed
          SwitchListTile(
            value: settings.defaultRepeatUntilCompleted,
            onChanged: settings.notificationsEnabled
                ? (val) => controller.setDefaultRepeatUntilCompleted(val)
                : null,
            title: Text(
              'Repeat overdue reminders by default',
              style: AppTextStyles.body,
            ),
            subtitle: Text(
              'Repeats alerts after deadline until task is marked complete.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (settings.defaultRepeatUntilCompleted) ...[
            const SizedBox(height: Spacing.xs),
            Text('DEFAULT REPEAT INTERVAL', style: AppTextStyles.label),
            const SizedBox(height: Spacing.xs),
            Wrap(
              spacing: Spacing.sm,
              children: [5, 10, 15, 30, 60].map((mins) {
                final label = mins == 60 ? '1 hour' : '$mins min';
                final selected = settings.defaultRepeatIntervalMinutes == mins;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: settings.notificationsEnabled
                      ? (_) => controller.setDefaultRepeatIntervalMinutes(mins)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.md),
          ],

          // Default Sound
          Text('DEFAULT SOUND', style: AppTextStyles.label),
          const SizedBox(height: Spacing.xs),
          DropdownButtonFormField<String>(
            initialValue: settings.defaultSound,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: NotificationSound.values.map((s) {
              return DropdownMenuItem(value: s.name, child: Text(s.label));
            }).toList(),
            onChanged: settings.notificationsEnabled
                ? (val) {
                    if (val != null) controller.setDefaultSound(val);
                  }
                : null,
          ),
          const SizedBox(height: Spacing.md),

          // Default Vibration
          Text('DEFAULT VIBRATION', style: AppTextStyles.label),
          const SizedBox(height: Spacing.xs),
          DropdownButtonFormField<String>(
            initialValue: settings.defaultVibration,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: NotificationVibration.values.map((v) {
              return DropdownMenuItem(value: v.name, child: Text(v.label));
            }).toList(),
            onChanged: settings.notificationsEnabled
                ? (val) {
                    if (val != null) controller.setDefaultVibration(val);
                  }
                : null,
          ),
          const SizedBox(height: Spacing.xxl),

          Text(
            'BUSY HOURS',
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Optional reminders are nudged out of your busy window. Deadline '
            'alerts and overdue reminders are always delivered.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SwitchListTile(
            value: settings.busyHoursEnabled,
            onChanged: (value) => controller.setBusyHours(enabled: value),
            title: Text('Enable busy hours', style: AppTextStyles.body),
            contentPadding: EdgeInsets.zero,
          ),
          if (settings.busyHoursEnabled) ...[
            _HourRow(
              label: 'Start',
              hour: settings.busyStartHour,
              onChanged: (hour) =>
                  controller.setBusyHours(enabled: true, startHour: hour),
            ),
            _HourRow(
              label: 'End',
              hour: settings.busyEndHour,
              onChanged: (hour) =>
                  controller.setBusyHours(enabled: true, endHour: hour),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final granted =
        await NotificationPermissionCoordinator.requestWithOptInFlow(
          context,
          ref,
        );
    if (granted) {
      await ref.read(settingsControllerProvider).setNotificationsEnabled(true);
    }
    await _refreshPermission();
  }

  /// Applies the daily-summary preference through the reminder service so the
  /// scheduling logic lives in exactly one place.
  Future<void> _applyDailySummary() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    await ref.read(reminderServiceProvider).syncDailySummary(settings);
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.status,
    required this.onEnable,
    required this.onOpenSettings,
  });

  final NotificationPermissionStatus status;
  final VoidCallback onEnable;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status.notificationsGranted) {
      return Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Notifications are enabled.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 20,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Notifications are turned off',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'DueMate can still track your tasks, but it cannot remind you '
            'until notifications are allowed.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              FilledButton(onPressed: onEnable, child: const Text('Allow')),
              const SizedBox(width: Spacing.sm),
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: AppTextStyles.body)),
          Expanded(
            child: Slider(
              value: hour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: _format(hour),
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              _format(hour),
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  String _format(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $ampm';
  }
}
