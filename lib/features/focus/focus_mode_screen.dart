import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/task_item.dart';
import '../../providers/clock_provider.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';

import '../../routes/app_routes.dart';

/// A deliberately simple focus timer.
///
/// Scope is intentionally small: pick one task, run a 25-minute timer, mark it
/// done. It is not a full Pomodoro system and does not pretend to be.
class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key, required this.taskId});

  final String taskId;

  static Future<void> open(BuildContext context, String taskId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.focusMode),
        builder: (_) => FocusModeScreen(taskId: taskId),
      ),
    );
  }

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  static const _defaultMinutes = 25;

  Timer? _timer;
  Duration _remaining = const Duration(minutes: _defaultMinutes);
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remaining.inSeconds <= 1) {
          timer.cancel();
          setState(() {
            _remaining = Duration.zero;
            _running = false;
          });
        } else {
          setState(() => _remaining -= const Duration(seconds: 1));
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = const Duration(minutes: _defaultMinutes);
    });
  }

  Future<void> _complete(TaskItem task) async {
    _timer?.cancel();
    final result = await ref.read(taskControllerProvider).completeTask(task.id);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task completed. Nice work.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTask = ref.watch(taskByIdProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: asyncTask.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Task unavailable')),
        data: (task) {
          if (task == null) {
            return const Center(child: Text('Task unavailable'));
          }
          return _buildBody(context, task);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskItem task) {
    final scheme = Theme.of(context).colorScheme;
    final clock = ref.watch(currentClockProvider);
    final info = task.deadlineInfo(now: clock);

    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'FOCUS',
            style: AppTextStyles.label.copyWith(
              color: scheme.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            task.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline,
          ),
          if (info.hasDeadline) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              info.relativeLabel,
              style: AppTextStyles.countdown.copyWith(
                color: info.isOverdue ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          _TimerRing(
            remaining: _remaining,
            total: const Duration(minutes: _defaultMinutes),
          ),
          const SizedBox(height: Spacing.xxl),
          Text(
            _formatDuration(_remaining),
            style: AppTextStyles.display.copyWith(
              fontSize: 44,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_running ? 'Pause' : 'Start'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _complete(task),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Mark complete'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.remaining, required this.total});

  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total.inSeconds == 0
        ? 0.0
        : remaining.inSeconds / total.inSeconds;
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          Icon(
            Icons.center_focus_strong_rounded,
            size: 40,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
