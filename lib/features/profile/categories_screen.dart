import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/category_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/category.dart';
import '../../providers/core_providers.dart';
import '../../providers/task_providers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/empty_state.dart';

/// Manage categories: create, edit, recolour, delete.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.categories),
        builder: (_) => const CategoriesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesValueProvider);
    final tasks = ref.watch(tasksValueProvider);

    final counts = <String, int>{};
    for (final task in tasks) {
      if (task.categoryId != null) {
        counts[task.categoryId!] = (counts[task.categoryId!] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: categories.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message:
                  'Categories help you group college, work and personal tasks.',
              actionLabel: 'New category',
              onAction: () => _showEditor(context, ref, null),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                120,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryTile(
                  category: category,
                  taskCount: counts[category.id] ?? 0,
                  onEdit: () => _showEditor(context, ref, category),
                  onDelete: () => _delete(
                    context,
                    ref,
                    category,
                    counts[category.id] ?? 0,
                    categories,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref,
    Category? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryEditor(existing: existing),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category category,
    int taskCount,
    List<Category> allCategories,
  ) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default category "${category.name}" cannot be deleted.',
          ),
        ),
      );
      return;
    }

    if (taskCount == 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: const Text(
            'Are you sure you want to delete this category? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(categoryRepositoryProvider).delete(category.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted.')),
          );
        }
      }
      return;
    }

    // taskCount > 0: safe task reassignment dialog
    final otherCategories =
        allCategories.where((c) => c.id != category.id).toList();
    Category? initialTarget = otherCategories
        .where((c) => c.name.toLowerCase() == 'other')
        .firstOrNull;
    initialTarget ??= otherCategories.firstOrNull;
    String? selectedTargetId = initialTarget?.id;
    bool makeUncategorized = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This category contains $taskCount ${taskCount == 1 ? 'task' : 'tasks'}.\n\n'
                'Tasks will NOT be deleted. Choose what to do with them:',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: Spacing.md),
              if (otherCategories.isNotEmpty) ...[
                RadioGroup<bool>(
                  groupValue: makeUncategorized,
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => makeUncategorized = val);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RadioListTile<bool>(
                        title: Text('Reassign tasks to:'),
                        value: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (!makeUncategorized)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32.0,
                            bottom: Spacing.sm,
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedTargetId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: otherCategories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Row(
                                        children: [
                                          Icon(c.icon,
                                              size: 16, color: c.color),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedTargetId = val),
                          ),
                        ),
                      const RadioListTile<bool>(
                        title:
                            Text('Remove category (leave uncategorized)'),
                        value: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Tasks will remain intact and become uncategorized.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Category'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final targetId = makeUncategorized ? null : selectedTargetId;
      await ref
          .read(categoryRepositoryProvider)
          .reassignTasks(category.id, targetId);
      await ref.read(categoryRepositoryProvider).delete(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetId != null
                  ? 'Category deleted and $taskCount tasks reassigned.'
                  : 'Category deleted and $taskCount tasks unassigned.',
            ),
          ),
        );
      }
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.taskCount,
    required this.onEdit,
    this.onDelete,
  });

  final Category category;
  final int taskCount;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onEdit,
        borderRadius: AppRadius.mdAll,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: scheme.outline),
          ),
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: AppTextStyles.body),
                    Text(
                      '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                tooltip: 'Actions for ${category.name}',
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else if (action == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: Spacing.sm),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !category.isDefault,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: category.isDefault
                              ? scheme.outline
                              : scheme.error,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          category.isDefault ? 'Default (Protected)' : 'Delete',
                          style: TextStyle(
                            color: category.isDefault
                                ? scheme.outline
                                : scheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.existing});

  final Category? existing;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late Color _color;
  String? _errorText;
  bool _saving = false;

  static const _palette = [
    Color(0xFF2B4A80),
    Color(0xFF2E9E6B),
    Color(0xFFC9821F),
    Color(0xFFC0453F),
    Color(0xFF7A5BA6),
    Color(0xFF3D7EA6),
    Color(0xFF4E8A6B),
    Color(0xFF8A6D3B),
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _iconKey = existing?.iconKey ?? CategoryIcons.defaultKey;
    _color = existing?.color ?? _palette.first;
    _nameController.addListener(() {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        MediaQuery.of(context).viewInsets.bottom + Spacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New category' : 'Edit category',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Thesis',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'ICON',
              style: AppTextStyles.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final key in CategoryIcons.keys)
                  InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: AppRadius.smAll,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _iconKey == key
                            ? _color.withValues(alpha: 0.16)
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: _iconKey == key
                              ? _color
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.resolve(key),
                        size: 20,
                        color: _iconKey == key
                            ? _color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'COLOUR',
              style: AppTextStyles.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final color in _palette)
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _color == color
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.existing == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Category name cannot be empty');
      return;
    }

    final categories = ref.read(categoriesValueProvider);
    final isDuplicate = categories.any(
      (c) =>
          c.id != widget.existing?.id &&
          c.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _errorText = 'A category named "$name" already exists');
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(categoryRepositoryProvider);
    final category =
        widget.existing?.copyWith(
          name: name,
          iconKey: _iconKey,
          color: _color,
        ) ??
        Category(
          id: repo.newId(),
          name: name,
          iconKey: _iconKey,
          color: _color,
          sortOrder: 99,
          createdAt: DateTime.now(),
        );

    await repo.upsert(category);
    if (mounted) Navigator.of(context).maybePop();
  }
}
