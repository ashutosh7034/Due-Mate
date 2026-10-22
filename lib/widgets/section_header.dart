import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';

/// A dashboard section header: an uppercase eyebrow, an optional count and an
/// optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.accentColor,
    this.trailing,
  });

  final String title;
  final int? count;
  final Color? accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xs,
        right: Spacing.xs,
        bottom: Spacing.md,
        top: Spacing.xs,
      ),
      child: Row(
        children: [
          if (accentColor != null) ...[
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: color),
          ),
          if (count != null) ...[
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.label.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Convenience accent used for the "overdue" section.
Color overdueAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFE98A85)
    : AppColors.danger;
