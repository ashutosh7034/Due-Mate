import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/backup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../providers/task_providers.dart';

import '../../routes/app_routes.dart';

/// Screen allowing users to export, validate, and restore task data safely.
class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.dataManagement),
        builder: (_) => const DataManagementScreen(),
      ),
    );
  }

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  final _importController = TextEditingController();
  BackupValidationResult? _validationResult;
  bool _isExporting = false;
  bool _isRestoring = false;
  bool _mergeMode = true;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _onImportTextChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() => _validationResult = null);
      return;
    }
    final backupService = ref.read(backupServiceProvider);
    final result = backupService.validateBackup(text);
    setState(() => _validationResult = result);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final json = await backupService.exportBackupData();

      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Text('Backup Exported'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your DueMate tasks, categories, and reminders have been exported to JSON and copied to your clipboard.',
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${json.length} characters copied. You can paste and save this in notes, an email, or a backup file.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _importController.text = data.text!;
      _onImportTextChanged(data.text!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      }
    }
  }

  Future<void> _performRestore() async {
    final validation = _validationResult;
    if (validation == null || !validation.isValid) return;

    if (!_mergeMode) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace All Data?'),
          content: const Text(
            'This will delete all current tasks and categories and replace them with the backup content. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace Data'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isRestoring = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final result = await backupService.restoreBackup(
        _importController.text,
        mergeMode: _mergeMode,
      );

      // Refresh tasks
      ref.invalidate(allTasksProvider);
      ref.invalidate(categoriesProvider);

      if (mounted) {
        _importController.clear();
        setState(() => _validationResult = null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully restored ${result.tasksRestored} tasks and ${result.categoriesRestored} categories.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksValueProvider);
    final categories = ref.watch(categoriesValueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          // Current Database Overview
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storage_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text('Current Database', style: AppTextStyles.title),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Stored safely in local SQLite. You currently have ${tasks.length} total tasks and ${categories.length} categories.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Section 1: Export
          Text('Backup & Export', style: AppTextStyles.title),
          const SizedBox(height: Spacing.xs),
          Text(
            'Export your tasks, subtasks, and reminders to standard JSON format.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          FilledButton.icon(
            onPressed: _isExporting ? null : _exportData,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Export Backup (Copy JSON)'),
          ),

          const SizedBox(height: Spacing.xxl),

          // Section 2: Import & Restore
          Text('Restore from Backup', style: AppTextStyles.title),
          const SizedBox(height: Spacing.xs),
          Text(
            'Paste your exported DueMate JSON backup below to safely validate and restore tasks.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: Spacing.md),

          TextField(
            controller: _importController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Paste backup JSON payload here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded),
                tooltip: 'Paste from clipboard',
                onPressed: _pasteFromClipboard,
              ),
            ),
            onChanged: _onImportTextChanged,
          ),
          const SizedBox(height: Spacing.sm),

          // Validation feedback box
          if (_validationResult != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: _validationResult!.isValid
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _validationResult!.isValid
                      ? Colors.green
                      : Colors.redAccent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _validationResult!.isValid
                            ? Icons.verified_rounded
                            : Icons.error_outline_rounded,
                        color: _validationResult!.isValid
                            ? Colors.green
                            : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        _validationResult!.isValid
                            ? 'Valid DueMate Backup'
                            : 'Invalid Backup Payload',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _validationResult!.isValid
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  if (_validationResult!.isValid) ...[
                    Text(
                      '• Tasks found: ${_validationResult!.taskCount}\n'
                      '• Categories found: ${_validationResult!.categoryCount}\n'
                      '• Reminders found: ${_validationResult!.reminderCount}\n'
                      '• Version: ${_validationResult!.version}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ] else ...[
                    Text(
                      _validationResult!.errorMessage ?? 'Unknown error',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Mode toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Merge with existing tasks'),
              subtitle: const Text(
                'Preserves current tasks and adds or updates backed-up items',
              ),
              value: _mergeMode,
              onChanged: (val) => setState(() => _mergeMode = val),
            ),
            const SizedBox(height: Spacing.md),

            FilledButton.icon(
              onPressed: (_isRestoring || !_validationResult!.isValid)
                  ? null
                  : _performRestore,
              style: FilledButton.styleFrom(
                backgroundColor: _mergeMode
                    ? AppColors.primary
                    : Colors.redAccent,
              ),
              icon: _isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(
                _mergeMode ? 'Restore & Merge Tasks' : 'Replace All Tasks',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
