import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../providers/task_controller.dart';
import '../../../providers/task_providers.dart';
import '../snooze_sheet.dart';
import '../task_details_screen.dart';

/// Dedicated in-app alarm screen/dialog for Type C alerts.
/// Displays urgent deadline alert with Mark Completed, Snooze, Open Task, and Dismiss.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.taskId});

  final String taskId;

  static Future<void> show(BuildContext context, String taskId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmScreen(taskId: taskId),
      ),
    );
  }

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Refresh overdue ticker every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskByIdProvider(widget.taskId));
    final scheme = Theme.of(context).colorScheme;

    return taskAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Alarm')),
        body: const Center(child: Text('Could not load task details.')),
      ),
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alarm')),
            body: const Center(child: Text('Task no longer exists.')),
          );
        }

        final now = DateTime.now();
        final deadline = task.deadline;
        final localDeadline = deadline == null
            ? null
            : (deadline.isUtc ? deadline.toLocal() : deadline);
        final isOverdue = localDeadline != null && localDeadline.isBefore(now);
        final elapsed = localDeadline != null
            ? now.difference(localDeadline)
            : Duration.zero;

        String overdueLabel = 'Due now';
        if (isOverdue) {
          if (elapsed.inDays > 0) {
            overdueLabel =
                'Overdue by ${elapsed.inDays} ${elapsed.inDays == 1 ? 'day' : 'days'}';
          } else if (elapsed.inHours > 0) {
            overdueLabel =
                'Overdue by ${elapsed.inHours} ${elapsed.inHours == 1 ? 'hour' : 'hours'}';
          } else {
            final mins = elapsed.inMinutes.clamp(1, 60);
            overdueLabel =
                'Overdue by $mins ${mins == 1 ? 'minute' : 'minutes'}';
          }
        }

        return Scaffold(
          backgroundColor: scheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top dismiss shortcut
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Dismiss alert',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Center Alarm Graphic & Details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [scheme.error, scheme.errorContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.error.withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.alarm_on_rounded,
                            size: 56,
                            color: scheme.onError,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxl),

                      // Urgent Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          overdueLabel.toUpperCase(),
                          style: AppTextStyles.label.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // Task Title
                      Text(
                        task.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),

                      if (localDeadline != null)
                        Text(
                          'Deadline: ${AppDateFormat.dateAndTime(localDeadline)}',
                          style: AppTextStyles.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),

                      if (task.repeatUntilCompleted) ...[
                        const SizedBox(height: Spacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: Spacing.xs),
                              Text(
                                'Repeats every ${task.repeatIntervalMinutes}m (${task.currentRepeatCount}/${task.maxRepeatCount} sent)',
                                style: AppTextStyles.caption.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom Action Buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mark Completed
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);
                            final res = await ref
                                .read(taskControllerProvider)
                                .completeTask(task.id);
                            if (nav.mounted) nav.pop();
                            if (res.isSuccess) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Completed "${task.title}".'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Mark Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),

                      // Snooze and Open Task row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  SnoozeSheet.show(context, task);
                                },
                                icon: const Icon(Icons.snooze_rounded),
                                label: const Text('Snooze'),
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  TaskDetailsScreen.open(context, task.id);
                                },
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Open Task'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),

                      // Dismiss alert button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Dismiss Alert',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
