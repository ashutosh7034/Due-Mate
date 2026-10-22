import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../models/user_settings.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/priority_badge.dart';
import 'widgets/reminder_selector.dart';

/// Full task editor, shown as a scrollable modal bottom sheet.
///
/// Two modes:
///  * create — starts from [initialTitle] and an optional parsed [initialDraft]
///  * edit   — starts from [existing]
class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({
    super.key,
    this.existing,
    this.initialTitle,
    this.initialDeadline,
    this.initialPriority,
  });

  final TaskItem? existing;
  final String? initialTitle;
  final DateTime? initialDeadline;
  final Priority? initialPriority;

  static Future<bool?> show(
    BuildContext context, {
    TaskItem? existing,
    String? initialTitle,
    DateTime? initialDeadline,
    Priority? initialPriority,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: TaskEditorSheet(
          existing: existing,
          initialTitle: initialTitle,
          initialDeadline: initialDeadline,
          initialPriority: initialPriority,
        ),
      ),
    );
  }

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _customTitleController;
  late final TextEditingController _customBodyController;

  TaskDraft _draft = TaskDraft();
  bool _saving = false;
  String? _error;
  bool _loadedExisting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(
      text: existing?.title ?? widget.initialTitle ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _customTitleController = TextEditingController(
      text: existing?.customNotificationTitle ?? '',
    );
    _customBodyController = TextEditingController(
      text: existing?.customNotificationBody ?? '',
    );

    final settings = ref.read(settingsProvider).value ?? const UserSettings();
    _draft = existing != null
        ? TaskDraft.fromTask(existing)
        : TaskDraft.withDefaults(
            settings,
            title: widget.initialTitle ?? '',
            deadline: widget.initialDeadline,
            priority: widget.initialPriority ?? Priority.medium,
          );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _customTitleController.dispose();
    _customBodyController.dispose();
    super.dispose();
  }

  /// Hydrates the editor from an existing task, including its reminders and
  /// subtasks, once the async data is available.
  void _hydrate(
    TaskItem task,
    List<TaskReminder> reminders,
    List<TaskItem> subtasks,
  ) {
    if (_loadedExisting) return;
    _loadedExisting = true;
    _draft.reminders = reminders
        .where((r) => r.kind != ReminderKind.overdue)
        .map(
          (r) => ReminderSpec(
            kind: r.kind,
            minutesBefore: r.minutesBefore,
            customAt: r.kind == ReminderKind.custom ? r.scheduledAt : null,
          ),
        )
        .toList();
    _draft.subtasks = subtasks
        .map(
          (s) => SubtaskDraft(
            id: s.id,
            title: s.title,
            isCompleted: s.isCompleted,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesValueProvider);

    if (_isEditing) {
      final task = ref.watch(taskByIdProvider(widget.existing!.id)).value;
      final reminders =
          ref.watch(remindersForTaskProvider(widget.existing!.id)).value ?? [];
      final subtasks =
          ref.watch(subtasksProvider(widget.existing!.id)).value ?? [];
      if (task != null) _hydrate(task, reminders, subtasks);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Column(
          children: [
            _Handle(
              title: _isEditing ? 'Edit task' : 'New task',
              onClose: () => Navigator.of(context).maybePop(false),
            ),
            Divider(color: scheme.outline, height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.xl,
                    Spacing.xl,
                    Spacing.xxxl,
                  ),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      scrollPadding: const EdgeInsets.all(120),
                      autofocus: !_isEditing && widget.initialTitle == null,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        hintText: 'e.g. Submit project report',
                        counterText: '',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Give your task a title.'
                          : null,
                      onChanged: (value) => _draft.title = value,
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _descriptionController,
                      scrollPadding: const EdgeInsets.all(120),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Any useful detail',
                        counterText: '',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (value) => _draft.description = value,
                    ),
                    const SizedBox(height: Spacing.xxl),

                    FormSection(
                      title: 'Priority',
                      child: PrioritySelector(
                        value: _draft.priority,
                        onChanged: (value) =>
                            setState(() => _draft.priority = value),
                      ),
                    ),

                    FormSection(
                      title: 'Category',
                      child: _CategoryPicker(
                        categories: categories,
                        selectedId: _draft.categoryId,
                        onChanged: (id) =>
                            setState(() => _draft.categoryId = id),
                      ),
                    ),

                    FormSection(
                      title: 'Deadline',
                      child: Column(
                        children: [
                          PickerField(
                            icon: Icons.event_rounded,
                            label: 'Due date',
                            value: _draft.deadline == null
                                ? 'No deadline'
                                : AppDateFormat.fullDate(_draft.deadline!),
                            isPlaceholder: _draft.deadline == null,
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: Spacing.sm),
                          PickerField(
                            icon: Icons.schedule_rounded,
                            label: 'Due time',
                            value: _draft.deadline == null
                                ? 'Not set'
                                : AppDateFormat.time(_draft.deadline!),
                            isPlaceholder: _draft.deadline == null,
                            onTap: _draft.deadline == null ? null : _pickTime,
                          ),
                          if (_draft.deadline != null) ...[
                            const SizedBox(height: Spacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _draft.deadline = null;
                                  _draft.reminders = [];
                                }),
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                label: const Text('Remove deadline'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    FormSection(
                      title: 'Reminders',
                      description:
                          'Add as many as you need. The closest one and the '
                          'deadline alert are always delivered, even during busy hours.',
                      child: ReminderSelector(
                        specs: _draft.reminders,
                        deadline: _draft.deadline,
                        onChanged: (specs) =>
                            setState(() => _draft.reminders = specs),
                      ),
                    ),

                    FormSection(
                      title: 'Alarms & Custom Alerts',
                      child: _AlarmSettingsSection(
                        draft: _draft,
                        customTitleController: _customTitleController,
                        customBodyController: _customBodyController,
                        onChanged: () => setState(() {}),
                      ),
                    ),

                    FormSection(
                      title: 'Repeat',
                      child: RecurrenceSelector(
                        type: _draft.recurrenceType,
                        days: _draft.recurrenceDays,
                        deadline: _draft.deadline,
                        onChanged: (type, days) => setState(() {
                          _draft.recurrenceType = type;
                          _draft.recurrenceDays = days;
                        }),
                      ),
                    ),

                    FormSection(
                      title: 'Subtasks',
                      description: 'Break the task into smaller steps.',
                      child: _SubtaskEditor(
                        drafts: _draft.subtasks,
                        onChanged: (drafts) =>
                            setState(() => _draft.subtasks = drafts),
                      ),
                    ),

                    FormSection(
                      title: 'Notes',
                      child: TextFormField(
                        controller: _notesController,
                        scrollPadding: const EdgeInsets.all(120),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Anything else worth remembering',
                        ),
                        onChanged: (value) => _draft.notes = value,
                      ),
                    ),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: scheme.onErrorContainer,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isEditing ? 'Save changes' : 'Add task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _draft.deadline ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select deadline',
    );
    if (date == null || !mounted) return;
    final existing = _draft.deadline;
    setState(() {
      _draft.deadline = DateTime(
        date.year,
        date.month,
        date.day,
        existing?.hour ?? 23,
        existing?.minute ?? 59,
      );
    });
  }

  Future<void> _pickTime() async {
    final initial = _draft.deadline ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      final date = _draft.deadline ?? DateTime.now();
      _draft.deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _draft.title = _titleController.text;
    _draft.customNotificationTitle = _customTitleController.text.trim().isEmpty
        ? null
        : _customTitleController.text.trim();
    _draft.customNotificationBody = _customBodyController.text.trim().isEmpty
        ? null
        : _customBodyController.text.trim();
    final validationError = _draft.validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = ref.read(taskControllerProvider);
    final result = _isEditing
        ? await controller.updateTask(widget.existing!, _draft)
        : await controller.createTask(_draft);

    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Task updated' : 'Task added')),
      );
    } else {
      setState(() {
        _saving = false;
        _error = result.error;
      });
    }
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.md,
        Spacing.sm,
        Spacing.md,
      ),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.title),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        SelectChip(
          label: 'None',
          selected: selectedId == null,
          onTap: () => onChanged(null),
        ),
        for (final category in categories)
          SelectChip(
            label: category.name,
            selected: selectedId == category.id,
            accentColor: category.color,
            onTap: () => onChanged(category.id),
            leading: Icon(
              category.icon,
              size: 14,
              color: selectedId == category.id
                  ? category.color
                  : scheme.onSurfaceVariant,
            ),
          ),
        SelectChip(
          label: 'New',
          selected: false,
          onTap: () async {
            final created = await showDialog<String>(
              context: context,
              builder: (_) => const _QuickCategoryDialog(),
            );
            if (created != null) onChanged(created);
          },
          leading: const Icon(Icons.add_rounded, size: 14),
        ),
      ],
    );
  }
}

class _SubtaskEditor extends StatefulWidget {
  const _SubtaskEditor({required this.drafts, required this.onChanged});

  final List<SubtaskDraft> drafts;
  final ValueChanged<List<SubtaskDraft>> onChanged;

  @override
  State<_SubtaskEditor> createState() => _SubtaskEditorState();
}

class _SubtaskEditorState extends State<_SubtaskEditor> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onChanged([...widget.drafts, SubtaskDraft(title: title)]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.drafts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    widget.drafts[i].title,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove subtask',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    final next = [...widget.drafts]..removeAt(i);
                    widget.onChanged(next);
                  },
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a subtask',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton.filledTonal(
              onPressed: _add,
              tooltip: 'Add subtask',
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

/// Minimal inline category creation from the task editor.
class _QuickCategoryDialog extends ConsumerStatefulWidget {
  const _QuickCategoryDialog();

  @override
  ConsumerState<_QuickCategoryDialog> createState() =>
      _QuickCategoryDialogState();
}

class _QuickCategoryDialogState extends ConsumerState<_QuickCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Category name'),
        onSubmitted: (_) => _create(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _create, child: const Text('Create')),
      ],
    );
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(categoryRepositoryProvider);
    final id = repo.newId();
    final category = Category(
      id: id,
      name: name,
      iconKey: 'folder',
      color: Theme.of(context).colorScheme.primary,
      createdAt: DateTime.now(),
      sortOrder: 99,
    );
    await repo.upsert(category);
    if (mounted) Navigator.of(context).pop(id);
  }
}

class _AlarmSettingsSection extends StatefulWidget {
  const _AlarmSettingsSection({
    required this.draft,
    required this.customTitleController,
    required this.customBodyController,
    required this.onChanged,
  });

  final TaskDraft draft;
  final TextEditingController customTitleController;
  final TextEditingController customBodyController;
  final VoidCallback onChanged;

  @override
  State<_AlarmSettingsSection> createState() => _AlarmSettingsSectionState();
}

class _AlarmSettingsSectionState extends State<_AlarmSettingsSection> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.draft.repeatUntilCompleted ||
        widget.draft.alarmType != AlarmType.standard ||
        (widget.draft.customNotificationTitle?.isNotEmpty ?? false) ||
        (widget.draft.customNotificationBody?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = widget.draft;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      draft.alarmType.icon,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder & Alarm Settings',
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                        ),
                        Text(
                          '${draft.alarmType.label} • ${draft.repeatUntilCompleted ? "Repeats every ${draft.repeatIntervalMinutes}m" : "No repeat"}',
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALERT URGENCY / TYPE', style: AppTextStyles.label),
                  const SizedBox(height: Spacing.xs),
                  RadioGroup<AlarmType>(
                    groupValue: draft.alarmType,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => draft.alarmType = val);
                        widget.onChanged();
                      }
                    },
                    child: Column(
                      children: [
                        for (final type in AlarmType.values)
                          RadioListTile<AlarmType>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              type.label,
                              style: AppTextStyles.bodySmall,
                            ),
                            subtitle: Text(
                              type.description,
                              style: AppTextStyles.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            value: type,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Repeat until completed'),
                    subtitle: Text(
                      'Continues nudging after deadline until marked complete.',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    value: draft.repeatUntilCompleted,
                    onChanged: (val) {
                      setState(() => draft.repeatUntilCompleted = val);
                      widget.onChanged();
                    },
                  ),
                  if (draft.repeatUntilCompleted) ...[
                    const SizedBox(height: Spacing.sm),
                    Text('REPEAT INTERVAL', style: AppTextStyles.label),
                    const SizedBox(height: Spacing.xs),
                    Wrap(
                      spacing: Spacing.sm,
                      children: [5, 10, 15, 30, 60].map((mins) {
                        final label = mins == 60 ? '1 hour' : '$mins min';
                        final selected = draft.repeatIntervalMinutes == mins;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (sel) {
                            if (sel) {
                              setState(
                                () => draft.repeatIntervalMinutes = mins,
                              );
                              widget.onChanged();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text('MAXIMUM REPEATS', style: AppTextStyles.label),
                    const SizedBox(height: Spacing.xs),
                    Wrap(
                      spacing: Spacing.sm,
                      children: [3, 5, 10, 20].map((count) {
                        final selected = draft.maxRepeatCount == count;
                        return ChoiceChip(
                          label: Text('$count times'),
                          selected: selected,
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => draft.maxRepeatCount = count);
                              widget.onChanged();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Bounded limit prevents excessive battery drain.',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.lg),
                  Text('SOUND', style: AppTextStyles.label),
                  const SizedBox(height: Spacing.xs),
                  DropdownButtonFormField<NotificationSound>(
                    initialValue: draft.soundChoice,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: NotificationSound.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => draft.soundChoice = val);
                        widget.onChanged();
                      }
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                  Text('VIBRATION', style: AppTextStyles.label),
                  const SizedBox(height: Spacing.xs),
                  DropdownButtonFormField<NotificationVibration>(
                    initialValue: draft.vibrationChoice,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: NotificationVibration.values.map((v) {
                      return DropdownMenuItem(value: v, child: Text(v.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => draft.vibrationChoice = val);
                        widget.onChanged();
                      }
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'CUSTOM NOTIFICATION CONTENT',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: Spacing.xs),
                  TextFormField(
                    controller: widget.customTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Custom title (optional)',
                      hintText: 'Leave empty to use task title',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextFormField(
                    controller: widget.customBodyController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Custom message (optional)',
                      hintText: 'Leave empty to use deadline summary',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
