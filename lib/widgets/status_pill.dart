import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';
import '../models/enums.dart';

/// A compact, colour-coded status chip with a label.
///
/// Colour is a secondary cue; the text label always conveys the status.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.dense = false});

  final TaskStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color fg;
    late final Color bg;
    switch (status) {
      case TaskStatus.overdue:
        fg = isDark ? const Color(0xFFE98A85) : AppColors.danger;
        bg = isDark ? const Color(0xFF3A1D1B) : AppColors.dangerContainer;
      case TaskStatus.completed:
        fg = isDark ? const Color(0xFF64D3A3) : AppColors.success;
        bg = isDark ? const Color(0xFF16352A) : AppColors.successContainer;
      case TaskStatus.inProgress:
        fg = scheme.primary;
        bg = isDark
            ? AppColors.primaryContainerDark
            : AppColors.primaryContainer;
      case TaskStatus.cancelled:
        fg = scheme.onSurfaceVariant;
        bg = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant;
      case TaskStatus.notStarted:
        fg = scheme.onSurfaceVariant;
        bg = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Spacing.sm : Spacing.md,
        vertical: dense ? 2 : Spacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A small countdown / deadline label with an icon.
class DeadlineLabel extends StatelessWidget {
  const DeadlineLabel({
    super.key,
    required this.label,
    required this.isOverdue,
    this.isDueSoon = false,
    this.icon = Icons.schedule_rounded,
  });

  final String label;
  final bool isOverdue;
  final bool isDueSoon;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isOverdue
        ? (isDark ? const Color(0xFFE98A85) : AppColors.danger)
        : isDueSoon
        ? (isDark ? const Color(0xFFE7B567) : AppColors.warning)
        : scheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: Spacing.xs),
        Text(label, style: AppTextStyles.countdown.copyWith(color: color)),
      ],
    );
  }
}
