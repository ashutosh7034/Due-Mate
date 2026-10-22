import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/task_item.dart';
import '../../providers/task_controller.dart';

/// Modal bottom sheet allowing users to snooze an upcoming or overdue reminder.
/// Supports 5m, 10m, 15m, 30m, 1h, custom date & time picker, and "remind me again" interval.
class SnoozeSheet extends ConsumerStatefulWidget {
  const SnoozeSheet({super.key, required this.task});

  final TaskItem task;

  static Future<void> show(BuildContext context, TaskItem task) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SnoozeSheet(task: task),
    );
  }

  @override
  ConsumerState<SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends ConsumerState<SnoozeSheet> {
  int? _selectedRepeatInterval;

  @override
  void initState() {
    super.initState();
    _selectedRepeatInterval = widget.task.repeatIntervalMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.snooze_rounded,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Snooze Reminder', style: AppTextStyles.subtitle),
                    Text(
                      widget.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),

          // Optional "Remind me again" repeat interval
          Text(
            'REPEAT INTERVAL AFTER SNOOZE',
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RepeatIntervalChip(
                  label: '5 min',
                  interval: 5,
                  selected: _selectedRepeatInterval == 5,
                  onSelected: () => setState(() => _selectedRepeatInterval = 5),
                ),
                _RepeatIntervalChip(
                  label: '10 min',
                  interval: 10,
                  selected: _selectedRepeatInterval == 10,
                  onSelected: () =>
                      setState(() => _selectedRepeatInterval = 10),
                ),
                _RepeatIntervalChip(
                  label: '15 min',
                  interval: 15,
                  selected: _selectedRepeatInterval == 15,
                  onSelected: () =>
                      setState(() => _selectedRepeatInterval = 15),
                ),
                _RepeatIntervalChip(
                  label: '30 min',
                  interval: 30,
                  selected: _selectedRepeatInterval == 30,
                  onSelected: () =>
                      setState(() => _selectedRepeatInterval = 30),
                ),
                _RepeatIntervalChip(
                  label: '1 hour',
                  interval: 60,
                  selected: _selectedRepeatInterval == 60,
                  onSelected: () =>
                      setState(() => _selectedRepeatInterval = 60),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          Text(
            'CHOOSE SNOOZE DURATION',
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.sm),
          _SnoozeTile(
            title: '5 minutes',
            subtitle: 'Quick nudge',
            icon: Icons.timer_outlined,
            onTap: () => _applySnooze(const Duration(minutes: 5)),
          ),
          _SnoozeTile(
            title: '10 minutes',
            subtitle: 'Recommended',
            icon: Icons.timer_outlined,
            onTap: () => _applySnooze(const Duration(minutes: 10)),
          ),
          _SnoozeTile(
            title: '15 minutes',
            subtitle: 'Short break',
            icon: Icons.snooze_rounded,
            onTap: () => _applySnooze(const Duration(minutes: 15)),
          ),
          _SnoozeTile(
            title: '30 minutes',
            subtitle: 'Half hour',
            icon: Icons.access_time_rounded,
            onTap: () => _applySnooze(const Duration(minutes: 30)),
          ),
          _SnoozeTile(
            title: '1 hour',
            subtitle: 'Later today',
            icon: Icons.hourglass_bottom_rounded,
            onTap: () => _applySnooze(const Duration(hours: 1)),
          ),
          _SnoozeTile(
            title: 'Custom date & time...',
            subtitle: 'Pick exact date and time',
            icon: Icons.edit_calendar_rounded,
            onTap: _pickCustomDateTimeSnooze,
          ),
        ],
      ),
    );
  }

  Future<void> _applySnooze(
    Duration duration, {
    DateTime? customDateTime,
  }) async {
    Navigator.of(context).pop();
    final result = await ref
        .read(taskControllerProvider)
        .snoozeTask(
          widget.task.id,
          duration,
          customDateTime: customDateTime,
          customRepeatIntervalMinutes: _selectedRepeatInterval,
        );
    if (!mounted) return;

    if (result.isSuccess) {
      final label = customDateTime != null
          ? 'until ${_formatDateTime(customDateTime)}'
          : (duration.inMinutes < 60
                ? 'for ${duration.inMinutes} minutes'
                : 'for ${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder snoozed $label.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not snooze reminder.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickCustomDateTimeSnooze() async {
    final now = DateTime.now();
    // 1. Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    // 2. Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: TimeOfDay.now().minute,
      ),
    );
    if (pickedTime == null || !mounted) return;

    final targetDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (targetDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time in the future.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final diff = targetDateTime.difference(DateTime.now());
    await _applySnooze(diff, customDateTime: targetDateTime);
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day}/${dt.month} at $h:$m $ampm';
  }
}

class _RepeatIntervalChip extends StatelessWidget {
  const _RepeatIntervalChip({
    required this.label,
    required this.interval,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int interval;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _SnoozeTile extends StatelessWidget {
  const _SnoozeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.primary, size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
