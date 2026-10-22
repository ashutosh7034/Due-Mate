import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';
import '../models/enums.dart';

/// A small, restrained priority indicator.
///
/// Priority is communicated with an icon **and** a label so status never
/// relies on colour alone (accessibility requirement).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
    this.compact = false,
  });

  final Priority priority;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Low/medium priorities are intentionally understated.
    final emphasised = priority.isImportant;
    final color = priority.color;
    final fg = emphasised
        ? color
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      label: '${priority.label} priority',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: compact ? 13 : 15, color: fg),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              priority.label,
              style: AppTextStyles.caption.copyWith(
                color: fg,
                fontWeight: emphasised ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable priority selector for forms.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Priority value;
  final ValueChanged<Priority> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SegmentedButton<Priority>(
      showSelectedIcon: false,
      segments: [
        for (final priority in Priority.values)
          ButtonSegment(
            value: priority,
            label: Text(priority.label, maxLines: 1, softWrap: false),
            icon: Icon(priority.icon, size: 14),
          ),
      ],
      selected: {value},
      onSelectionChanged: enabled
          ? (selection) => onChanged(selection.first)
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return value == Priority.urgent || value == Priority.high
                ? value.color
                : scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 2, vertical: Spacing.xs),
        ),
      ),
    );
  }
}
