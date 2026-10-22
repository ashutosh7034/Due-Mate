import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';

/// A friendly, specific empty state.
///
/// Deliberately avoids "No data found." — every empty state should reassure
/// the user and offer the next action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? Spacing.lg : Spacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacing.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
