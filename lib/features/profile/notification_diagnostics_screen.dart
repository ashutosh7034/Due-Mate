import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_permission_coordinator.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../providers/core_providers.dart';
import '../../routes/app_routes.dart';

/// Status and diagnostics screen for DueMate notifications, alarm access,
/// Android channels, and pending reminder schedules.
class NotificationDiagnosticsScreen extends ConsumerStatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.notificationDiagnostics),
        builder: (_) => const NotificationDiagnosticsScreen(),
      ),
    );
  }

  @override
  ConsumerState<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends ConsumerState<NotificationDiagnosticsScreen>
    with WidgetsBindingObserver {
  NotificationDiagnosticInfo? _info;
  bool _loading = true;
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDiagnostics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDiagnostics();
    }
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);
    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    final diagnostics = await service.getDiagnostics();
    if (mounted) {
      setState(() {
        _info = diagnostics;
        _loading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    final info = _info;
    if (info != null && !info.notificationsGranted) {
      final granted =
          await NotificationPermissionCoordinator.requestWithOptInFlow(
            context,
            ref,
          );
      if (!granted) return;
    }

    setState(() => _sendingTest = true);
    final service = ref.read(notificationServiceProvider);
    final ok = await service.sendTestNotification();
    if (mounted) {
      setState(() => _sendingTest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Test notification sent! Check your notification drawer.'
                : 'Failed to display test notification.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      await _loadDiagnostics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh diagnostics',
            onPressed: _loading ? null : _loadDiagnostics,
          ),
        ],
      ),
      body: _loading && info == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.md,
                Spacing.lg,
                Spacing.xxxl,
              ),
              children: [
                _buildOverviewCard(context, info),
                const SizedBox(height: Spacing.lg),
                _buildActionsSection(context, info),
                const SizedBox(height: Spacing.xl),
                _buildChannelsSection(context, info),
                const SizedBox(height: Spacing.xl),
                _buildPendingRemindersSection(context, info),
                const SizedBox(height: Spacing.xl),
                _buildSystemNotice(context),
              ],
            ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    NotificationDiagnosticInfo? info,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final notifsGranted = info?.notificationsGranted ?? false;
    final alarmStatus = info?.exactAlarmsStatus ?? ExactAlarmStatus.notRequired;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYSTEM STATUS',
              style: AppTextStyles.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Notification permission
            _StatusRow(
              icon: notifsGranted
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              iconColor: notifsGranted ? scheme.primary : scheme.error,
              title: 'Notification permission',
              value: notifsGranted ? 'Allowed' : 'Denied',
              valueColor: notifsGranted ? scheme.primary : scheme.error,
              subtitle: notifsGranted
                  ? 'DueMate is permitted to post notifications.'
                  : 'Notifications are blocked. Reminders cannot appear in drawer.',
            ),
            const Divider(height: Spacing.xl),

            // Reminder scheduling access
            _StatusRow(
              icon: switch (alarmStatus) {
                ExactAlarmStatus.available => Icons.alarm_on_rounded,
                ExactAlarmStatus.needsPermission => Icons.alarm_off_rounded,
                ExactAlarmStatus.notRequired => Icons.alarm_rounded,
              },
              iconColor: switch (alarmStatus) {
                ExactAlarmStatus.available => scheme.primary,
                ExactAlarmStatus.needsPermission => scheme.error,
                ExactAlarmStatus.notRequired => scheme.onSurfaceVariant,
              },
              title: 'Reminder scheduling access',
              value: switch (alarmStatus) {
                ExactAlarmStatus.available => 'Available',
                ExactAlarmStatus.needsPermission => 'Needs permission',
                ExactAlarmStatus.notRequired => 'Not required',
              },
              valueColor: switch (alarmStatus) {
                ExactAlarmStatus.available => scheme.primary,
                ExactAlarmStatus.needsPermission => scheme.error,
                ExactAlarmStatus.notRequired => scheme.onSurface,
              },
              subtitle: switch (alarmStatus) {
                ExactAlarmStatus.available =>
                  'Exact alarms are granted for precise deadline alerts.',
                ExactAlarmStatus.needsPermission => 'Android 12+ requires exact alarm permission for to-the-minute alerts.',
                ExactAlarmStatus.notRequired =>
                  'Exact alarms are not restricted on this platform.',
              },
            ),
            const Divider(height: Spacing.xl),

            // Can test notification be displayed
            _StatusRow(
              icon: notifsGranted
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              iconColor: notifsGranted
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
              title: 'Test notification delivery',
              value: notifsGranted ? 'Ready' : 'Blocked by permission',
              valueColor: notifsGranted ? scheme.primary : scheme.error,
              subtitle: notifsGranted
                  ? 'Ready to post test alerts with sound and vibration.'
                  : 'Grant notification permission first to receive test alerts.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    NotificationDiagnosticInfo? info,
  ) {
    final service = ref.read(notificationServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _sendingTest ? null : _sendTestNotification,
          icon: _sendingTest
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notification_add_rounded),
          label: const Text('Send test notification immediately'),
        ),
        const SizedBox(height: Spacing.sm),
        OutlinedButton.icon(
          onPressed: () => service.openSystemSettings(),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open Android notification settings'),
        ),
        if (info?.exactAlarmsStatus == ExactAlarmStatus.needsPermission) ...[
          const SizedBox(height: Spacing.sm),
          FilledButton.tonalIcon(
            onPressed: () =>
                service.requestPermissions(requestExactAlarms: true),
            icon: const Icon(Icons.alarm_add_rounded),
            label: const Text('Request exact alarm permission'),
          ),
        ],
      ],
    );
  }

  Widget _buildChannelsSection(
    BuildContext context,
    NotificationDiagnosticInfo? info,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final channels = info?.channels ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'NOTIFICATION CHANNELS',
              style: AppTextStyles.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${channels.length} registered',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Android channels manage sound, vibration, and drawer presentation independently. '
          'Settings modified by the user in Android Settings take precedence.',
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.md),
        if (channels.isEmpty)
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No custom channels returned by system yet. Default channels are configured in code.',
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          for (final channel in channels) ...[
            _ChannelCard(channel: channel),
            const SizedBox(height: Spacing.sm),
          ],
      ],
    );
  }

  Widget _buildPendingRemindersSection(
    BuildContext context,
    NotificationDiagnosticInfo? info,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final count = info?.pendingCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: Spacing.sm),
              Text('Pending OS Alarms', style: AppTextStyles.title),
              const Spacer(),
              Badge(
                label: Text('$count'),
                backgroundColor: scheme.primaryContainer,
                textColor: scheme.onPrimaryContainer,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            count == 0
                ? 'No future reminders currently queued in the Android AlarmManager.'
                : '$count scheduled reminder notification(s) registered with the system alarm manager.',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Android delivers exact alarms within seconds of the target time. If Battery Saver '
              'or aggressive vendor background policies are active, delivery timing may vary.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color valueColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTextStyles.body),
                  Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel});

  final AndroidNotificationChannel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final importanceName = switch (channel.importance) {
      Importance.max => 'Max',
      Importance.high => 'High (Heads-up banner)',
      Importance.defaultImportance => 'Default',
      Importance.low => 'Low (Quiet)',
      Importance.min => 'Min',
      Importance.none || Importance.unspecified => 'None',
    };

    final isHigh =
        channel.importance == Importance.high ||
        channel.importance == Importance.max;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(channel.name, style: AppTextStyles.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isHigh
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  importanceName,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHigh
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (channel.description != null &&
              channel.description!.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              channel.description!,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Icon(
                channel.playSound
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                channel.playSound ? 'Sound on' : 'Silent',
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Icon(
                channel.enableVibration
                    ? Icons.vibration
                    : Icons.smartphone_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                channel.enableVibration ? 'Vibration on' : 'No vibration',
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
