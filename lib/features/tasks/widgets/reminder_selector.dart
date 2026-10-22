import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../models/enums.dart';
import '../../../models/reminder.dart';
import '../../../widgets/form_fields.dart';

/// Multi-select reminder picker.
///
/// Users can stack several reminders on one task (e.g. 1 day, 3 hours and
/// 30 minutes before). A custom absolute time can be added too.
class ReminderSelector extends StatelessWidget {
  const ReminderSelector({
    super.key,
    required this.specs,
    required this.onChanged,
    this.deadline,
  });

  final List<ReminderSpec> specs;
  final ValueChanged<List<ReminderSpec>> onChanged;
  final DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deadline == null)
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            margin: const EdgeInsets.only(bottom: Spacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Set a deadline first to use reminders.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final preset in ReminderPresets.standard)
              _PresetChip(
                preset: preset,
                selected: _isSelected(preset),
                enabled: deadline != null,
                onTap: () => _toggle(preset),
              ),
            _CustomChip(
              enabled: deadline != null,
              selected: specs.any((s) => s.kind == ReminderKind.custom),
              onTap: deadline == null ? null : () => _pickCustom(context),
            ),
          ],
        ),
        if (specs.any((s) => s.kind == ReminderKind.custom)) ...[
          const SizedBox(height: Spacing.md),
          for (final spec in specs.where((s) => s.kind == ReminderKind.custom))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      spec.customAt == null
                          ? 'Custom time'
                          : AppDateFormat.dateAndTime(spec.customAt!),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove reminder',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      final next = specs
                          .where((s) => !identical(s, spec))
                          .toList(growable: false);
                      onChanged(next);
                    },
                  ),
                ],
              ),
            ),
        ],
        if (deadline != null && specs.isEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  'No reminder selected — one will be set at the deadline.',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _isSelected(ReminderPreset preset) {
    return specs.any(
      (s) => s.kind == preset.kind && s.minutesBefore == preset.minutesBefore,
    );
  }

  void _toggle(ReminderPreset preset) {
    final exists = _isSelected(preset);
    if (exists) {
      onChanged(
        specs
            .where(
              (s) =>
                  !(s.kind == preset.kind &&
                      s.minutesBefore == preset.minutesBefore),
            )
            .toList(growable: false),
      );
    } else {
      onChanged([
        ...specs,
        ReminderSpec(kind: preset.kind, minutesBefore: preset.minutesBefore),
      ]);
    }
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        specs
            .firstWhere(
              (s) => s.kind == ReminderKind.custom && s.customAt != null,
              orElse: () =>
                  const ReminderSpec(kind: ReminderKind.custom, customAt: null),
            )
            .customAt ??
        deadline ??
        now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final at = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onChanged([
      ...specs.where((s) => s.kind != ReminderKind.custom),
      ReminderSpec(kind: ReminderKind.custom, customAt: at),
    ]);
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ReminderPreset preset;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = preset.kind == ReminderKind.atDeadline
        ? Icons.event_available_rounded
        : Icons.alarm_rounded;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SelectChip(
        label: preset.label,
        selected: selected,
        onTap: enabled ? onTap : null,
        leading: Icon(
          icon,
          size: 14,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SelectChip(
        label: 'Custom',
        selected: selected,
        onTap: enabled ? onTap : null,
        leading: Icon(
          Icons.edit_calendar_rounded,
          size: 14,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Repeat-schedule picker.
class RecurrenceSelector extends StatelessWidget {
  const RecurrenceSelector({
    super.key,
    required this.type,
    required this.days,
    required this.onChanged,
    this.deadline,
  });

  final RecurrenceType type;
  final List<int> days;
  final void Function(RecurrenceType type, List<int> days) onChanged;
  final DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final option in RecurrenceType.values)
              SelectChip(
                label: option.label,
                selected: option == type,
                onTap: () => onChanged(option, days),
              ),
          ],
        ),
        if (type == RecurrenceType.customWeekly) ...[
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              for (var d = 1; d <= 7; d++)
                _DayChip(
                  day: d,
                  selected: days.contains(d),
                  onTap: () {
                    final next = [...days];
                    if (next.contains(d)) {
                      next.remove(d);
                    } else {
                      next.add(d);
                    }
                    next.sort();
                    onChanged(type, next);
                  },
                ),
            ],
          ),
          if (deadline == null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'A repeat schedule needs a deadline.',
              style: AppTextStyles.caption.copyWith(color: scheme.error),
            ),
          ],
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: _fullDay,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : scheme.surfaceContainerLow,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Text(
            _labels[day - 1],
            style: AppTextStyles.caption.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String get _fullDay => switch (day) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    _ => 'Sunday',
  };
}
