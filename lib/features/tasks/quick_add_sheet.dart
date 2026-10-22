import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/quick_add_parser.dart';
import '../../models/enums.dart';
import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_controller.dart';
import '../../widgets/priority_badge.dart';
import 'task_editor_sheet.dart';

/// Available quick deadline shortcuts in Quick Add.
enum QuickDeadlineShortcut {
  today('Today'),
  tomorrow('Tomorrow'),
  oneWeekLater('1 week later'),
  noDeadline('No deadline');

  const QuickDeadlineShortcut(this.label);
  final String label;
}

class _QuickAddAction {
  const _QuickAddAction({
    required this.openFullEditor,
    this.title,
    this.deadline,
    this.priority,
  });

  final bool openFullEditor;
  final String? title;
  final DateTime? deadline;
  final Priority? priority;
}

/// The fast path for adding a task.
///
/// The user types a sentence; the parser extracts a title, deadline and
/// priority, and shows what it understood so nothing is a surprise. "More
/// options" hands off to the full editor with the parsed values pre-filled.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.initialText});

  final String? initialText;

  static Future<void> show(BuildContext context, {String? initialText}) async {
    final result = await showModalBottomSheet<_QuickAddAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: QuickAddSheet(initialText: initialText),
      ),
    );

    if (result != null && result.openFullEditor && context.mounted) {
      await TaskEditorSheet.show(
        context,
        initialTitle: result.title,
        initialDeadline: result.deadline,
        initialPriority: result.priority,
      );
    }
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late final TextEditingController _controller;
  QuickAddResult? _parsed;
  QuickDeadlineShortcut? _selectedShortcut;
  DateTime? _manualDeadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _parsed = QuickAddParser.parse(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _parsed = value.trim().isEmpty ? null : QuickAddParser.parse(value);
    });
  }

  Future<void> _pickDateTime() async {
    final current = _getEffectiveDeadline() ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _manualDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  /// Evaluates the effective deadline using natural language parsing precedence,
  /// manual user overrides, and selected deadline shortcut chips.
  DateTime? _getEffectiveDeadline({DateTime? now}) {
    if (_selectedShortcut == QuickDeadlineShortcut.noDeadline) {
      return null;
    }

    if (_manualDeadline != null) {
      return _manualDeadline;
    }

    final clock = now ?? DateTime.now();
    final parsed = _parsed;
    final shortcut = _selectedShortcut;

    if (shortcut != null) {
      DateTime targetDate;
      switch (shortcut) {
        case QuickDeadlineShortcut.today:
          targetDate = DateTime(clock.year, clock.month, clock.day);
          break;
        case QuickDeadlineShortcut.tomorrow:
          targetDate = DateTime(clock.year, clock.month, clock.day + 1);
          break;
        case QuickDeadlineShortcut.oneWeekLater:
          targetDate = DateTime(clock.year, clock.month, clock.day + 7);
          break;
        case QuickDeadlineShortcut.noDeadline:
          return null;
      }

      int hour = 23;
      int minute = 59;
      // Natural language explicit parsed time takes precedence over 11:59 PM default
      if (parsed != null && parsed.matchedTime && parsed.deadline != null) {
        hour = parsed.deadline!.hour;
        minute = parsed.deadline!.minute;
      }

      return DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );
    }

    // No explicit shortcut clicked yet: use natural-language parsed deadline if present
    if (parsed != null && parsed.hasDeadline) {
      return parsed.deadline;
    }

    return null;
  }

  /// Effective shortcut for UI chip highlighted state.
  QuickDeadlineShortcut? get _effectiveShortcut {
    if (_selectedShortcut != null) return _selectedShortcut;
    final d = _manualDeadline ?? _parsed?.deadline;
    if (d == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final oneWeek = DateTime(now.year, now.month, now.day + 7);

    final target = DateTime(d.year, d.month, d.day);
    if (target.isAtSameMomentAs(today)) return QuickDeadlineShortcut.today;
    if (target.isAtSameMomentAs(tomorrow)) return QuickDeadlineShortcut.tomorrow;
    if (target.isAtSameMomentAs(oneWeek)) {
      return QuickDeadlineShortcut.oneWeekLater;
    }
    return null;
  }

  Future<void> _quickSave() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final parsed = _parsed ?? QuickAddParser.parse(text);
    final effectiveDeadline = _getEffectiveDeadline();
    final effectiveTitle =
        parsed.title.trim().isNotEmpty ? parsed.title.trim() : text;

    setState(() => _saving = true);

    try {
      final settings =
          ref.read(settingsProvider).value ?? const UserSettings();
      final draft = TaskDraft(
        title: effectiveTitle,
        deadline: effectiveDeadline,
        priority: parsed.priority ?? Priority.medium,
        alarmType: settings.resolvedDefaultAlarmType,
        repeatUntilCompleted: settings.defaultRepeatUntilCompleted,
        repeatIntervalMinutes: settings.defaultRepeatIntervalMinutes,
        soundChoice: settings.resolvedDefaultSound,
        vibrationChoice: settings.resolvedDefaultVibration,
      );
      final result =
          await ref.read(taskControllerProvider).createTask(draft);

      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added')),
        );
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not add the task.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add the task. Please try again.'),
        ),
      );
    }
  }

  void _openFullEditor() {
    final text = _controller.text.trim();
    final parsed = text.isEmpty ? null : QuickAddParser.parse(text);
    final effectiveDeadline = _getEffectiveDeadline();
    final effectiveTitle =
        (parsed?.title.trim().isNotEmpty ?? false)
            ? parsed!.title.trim()
            : (text.isNotEmpty ? text : null);

    Navigator.of(context).pop(
      _QuickAddAction(
        openFullEditor: true,
        title: effectiveTitle,
        deadline: effectiveDeadline,
        priority: parsed?.priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = _parsed;
    final effectiveDeadline = _getEffectiveDeadline();
    final effectiveShortcut = _effectiveShortcut;

    return SingleChildScrollView(
      child: Padding(
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
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: Spacing.sm),
                Text('Quick add', style: AppTextStyles.title),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              minLines: 1,
              maxLines: 3,
              onChanged: _onChanged,
              onSubmitted: (_) => _quickSave(),
              decoration: const InputDecoration(
                hintText: 'e.g. Submit assignment tomorrow at 7 PM',
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: QuickDeadlineShortcut.values.map((shortcut) {
                final isSelected = effectiveShortcut == shortcut;
                return ChoiceChip(
                  label: Text(shortcut.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedShortcut = shortcut;
                        if (shortcut == QuickDeadlineShortcut.noDeadline) {
                          _manualDeadline = null;
                        } else if (_manualDeadline != null) {
                          // Preserve manually chosen time of day across calendar shortcut selections
                          final clock = DateTime.now();
                          DateTime targetDate;
                          switch (shortcut) {
                            case QuickDeadlineShortcut.today:
                              targetDate =
                                  DateTime(clock.year, clock.month, clock.day);
                              break;
                            case QuickDeadlineShortcut.tomorrow:
                              targetDate = DateTime(
                                clock.year,
                                clock.month,
                                clock.day + 1,
                              );
                              break;
                            case QuickDeadlineShortcut.oneWeekLater:
                              targetDate = DateTime(
                                clock.year,
                                clock.month,
                                clock.day + 7,
                              );
                              break;
                            case QuickDeadlineShortcut.noDeadline:
                              targetDate = clock;
                              break;
                          }
                          _manualDeadline = DateTime(
                            targetDate.year,
                            targetDate.month,
                            targetDate.day,
                            _manualDeadline!.hour,
                            _manualDeadline!.minute,
                          );
                        }
                      } else {
                        _selectedShortcut = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if ((parsed != null && parsed.title.trim().isNotEmpty) ||
                effectiveDeadline != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNDERSTOOD',
                      style: AppTextStyles.label.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    if (parsed != null && parsed.title.trim().isNotEmpty)
                      _ParsedRow(
                        icon: Icons.title_rounded,
                        label: parsed.title,
                        muted: false,
                      ),
                    InkWell(
                      key: const ValueKey('quick_add_deadline_preview'),
                      onTap: _pickDateTime,
                      borderRadius: AppRadius.smAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: effectiveDeadline != null
                                  ? _ParsedRow(
                                      icon: Icons.schedule_rounded,
                                      label: AppDateFormat.dateAndTime(
                                        effectiveDeadline,
                                      ),
                                      muted: false,
                                    )
                                  : const _ParsedRow(
                                      icon: Icons.event_busy_rounded,
                                      label: 'No deadline (tap to set)',
                                      muted: true,
                                    ),
                            ),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (parsed?.priority != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs),
                        child: PriorityBadge(priority: parsed!.priority!),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _openFullEditor,
                    child: const Text('More options'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: (_saving || _controller.text.trim().isEmpty)
                        ? null
                        : _quickSave,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add task'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Tip: include words like "tomorrow", "7 PM" or "urgent" and they '
              'will be understood automatically.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedRow extends StatelessWidget {
  const _ParsedRow({
    required this.icon,
    required this.label,
    required this.muted,
  });

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: muted ? scheme.outline : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: muted ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
