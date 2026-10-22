import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../models/task_item.dart';
import '../../providers/task_controller.dart';
import '../../widgets/form_fields.dart';

/// A quick reschedule flow for overdue (or any) tasks.
///
/// Offers the common human choices first — later today, tomorrow, this
/// weekend — then a custom date/time, so recovering from an overdue task takes
/// one tap.
class RescheduleSheet extends ConsumerWidget {
  const RescheduleSheet({super.key, required this.task});

  final TaskItem task;

  static Future<void> show(BuildContext context, TaskItem task) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => RescheduleSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final existingTime = task.deadline != null
        ? TimeOfDay.fromDateTime(task.deadline!)
        : const TimeOfDay(hour: 23, minute: 59);

    DateTime at(int dayOffset) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      return DateTime(
        date.year,
        date.month,
        date.day,
        existingTime.hour,
        existingTime.minute,
      );
    }

    DateTime laterToday() {
      if (now.hour >= 21) {
        // Late night: set to 11:59 PM tonight
        return DateTime(now.year, now.month, now.day, 23, 59);
      }
      // If task deadline was earlier today, set to later today (at least 2 hours ahead or 18:00)
      final targetHour = (now.hour + 2 < 18)
          ? 18
          : (now.hour + 2).clamp(now.hour + 1, 23);
      final candidate = DateTime(now.year, now.month, now.day, targetHour, 0);
      if (candidate.isAfter(now)) return candidate;
      return DateTime(now.year, now.month, now.day, 23, 59);
    }

    final laterTodayTime = at(0).difference(now).inMinutes > 30
        ? at(0)
        : laterToday();

    final options = <_RescheduleOption>[
      _RescheduleOption(
        icon: Icons.today_rounded,
        label: 'Later today',
        dateTime: laterTodayTime,
      ),
      _RescheduleOption(
        icon: Icons.wb_sunny_outlined,
        label: 'Tomorrow',
        dateTime: at(1),
      ),
      _RescheduleOption(
        icon: Icons.weekend_outlined,
        label: 'This weekend',
        dateTime: _upcomingSaturday(now, existingTime),
      ),
      _RescheduleOption(
        icon: Icons.date_range_rounded,
        label: 'Next week',
        dateTime: at(7),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reschedule task', style: AppTextStyles.title),
          const SizedBox(height: Spacing.xs),
          Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: PickerField(
                icon: option.icon,
                label: option.label,
                value: AppDateFormat.relativeDayTime(option.dateTime),
                onTap: () => _apply(context, ref, option.dateTime),
                trailing: const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: Spacing.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickCustom(context, ref, existingTime),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text('Custom date & time'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    DateTime deadline,
  ) async {
    final result = await ref
        .read(taskControllerProvider)
        .reschedule(task.id, deadline);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Rescheduled to ${AppDateFormat.relativeDayTime(deadline)}'
              : result.error ?? 'Could not reschedule.',
        ),
      ),
    );
  }

  Future<void> _pickCustom(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initialTime,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: task.deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time == null || !context.mounted) return;
    await _apply(
      context,
      ref,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  DateTime _upcomingSaturday(DateTime now, TimeOfDay time) {
    var delta = (DateTime.saturday - now.weekday) % 7;
    if (delta == 0) delta = 7;
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: delta));
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _RescheduleOption {
  const _RescheduleOption({
    required this.icon,
    required this.label,
    required this.dateTime,
  });

  final IconData icon;
  final String label;
  final DateTime dateTime;
}
