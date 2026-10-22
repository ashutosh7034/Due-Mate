import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';

/// A labelled form section with a title and optional helper text.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (description != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            description!,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Spacing.sm),
        child,
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}

/// A tappable field row with a leading icon, title, value and chevron.
///
/// Used for date, time, category, repeat and reminder pickers.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isPlaceholder = false,
    this.trailing,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isPlaceholder;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: scheme.outline),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: accentColor ?? scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        color: isPlaceholder
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        fontWeight: isPlaceholder
                            ? FontWeight.w400
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable chip with an optional leading icon/colour.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leading,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.12)
          : scheme.surfaceContainerLow,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: selected ? accent : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: Spacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? accent : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
