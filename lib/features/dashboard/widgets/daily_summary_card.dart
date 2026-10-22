import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../models/dashboard_data.dart';
import '../../../providers/clock_provider.dart';

/// The compact "Today" summary card.
///
/// Every number comes from real task data — there is no placeholder analytics.
class DailySummaryCard extends ConsumerWidget {
  const DailySummaryCard({super.key, required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clock = ref.watch(currentClockProvider);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today', style: AppTextStyles.subtitle),
              const Spacer(),
              Text(
                _dateLabel(),
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (summary.total == 0 && summary.completed == 0)
            Text(
              'Nothing scheduled. A clear day.',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: Spacing.lg,
              runSpacing: Spacing.md,
              children: [
                _Stat(
                  value: '${summary.total}',
                  label: summary.total == 1 ? 'task' : 'tasks',
                ),
                if (summary.overdue > 0)
                  _Stat(
                    value: '${summary.overdue}',
                    label: 'overdue',
                    color: isDark
                        ? const Color(0xFFE98A85)
                        : const Color(0xFFC0453F),
                  ),
                if (summary.highPriority > 0)
                  _Stat(
                    value: '${summary.highPriority}',
                    label: 'high priority',
                    color: isDark
                        ? const Color(0xFFE7B567)
                        : const Color(0xFFC9821F),
                  ),
                if (summary.completed > 0)
                  _Stat(
                    value: '${summary.completed}',
                    label: 'completed',
                    color: isDark
                        ? const Color(0xFF64D3A3)
                        : const Color(0xFF2E9E6B),
                  ),
              ],
            ),
          if (summary.nextDeadline != null) ...[
            const SizedBox(height: Spacing.md),
            Divider(color: scheme.outline, height: 1),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Icon(
                  Icons.upcoming_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      children: [
                        const TextSpan(text: 'Next deadline '),
                        TextSpan(
                          text: summary.nextDeadline!
                              .deadlineInfo(now: clock)
                              .sentenceLabel,

                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    return AppDateFormat.fullDate(now);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: AppTextStyles.headline.copyWith(color: fg, fontSize: 20),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
