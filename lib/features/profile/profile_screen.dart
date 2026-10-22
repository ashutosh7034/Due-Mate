import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/user_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'categories_screen.dart';
import 'data_management_screen.dart';
import 'notification_diagnostics_screen.dart';
import 'notification_settings_screen.dart';

/// Profile & settings hub for DueMate.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();
    final tasks = ref.watch(tasksValueProvider);
    final categories = ref.watch(categoriesValueProvider);
    final currentUser = ref.watch(currentUserProvider);

    final open = tasks.where((t) => !t.isClosed).length;
    final done = tasks.where((t) => t.isCompleted).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.lg,
          120,
        ),
        children: [
          Text('Profile', style: AppTextStyles.headline),
          const SizedBox(height: Spacing.lg),
          _UserHeader(
            userName: currentUser?.fullName ?? 'DueMate User',
            userEmail: currentUser?.email ?? 'user@duemate.app',
            photoUrl: currentUser?.photoUrl,
            onEdit: () =>
                _editProfile(context, ref, currentUser?.fullName ?? ''),
            onChangePhoto: () =>
                _managePhoto(context, ref, currentUser?.photoUrl),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(value: '$open', label: 'Open tasks'),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatCard(value: '$done', label: 'Completed'),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatCard(
                  value: '${categories.length}',
                  label: 'Categories',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),
          _SettingsGroup(
            title: 'Preferences',
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: _themeLabel(settings.themeMode),
                onTap: () => AppearanceScreen.open(context),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: settings.notificationsEnabled
                    ? 'Reminders are on'
                    : 'Reminders are off',
                onTap: () => NotificationSettingsScreen.open(context),
              ),
              _SettingsTile(
                icon: Icons.troubleshoot_rounded,
                title: 'Notification Diagnostics',
                subtitle: 'Test sound, vibration & alarms',
                onTap: () => NotificationDiagnosticsScreen.open(context),
              ),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: '${categories.length} categories',
                onTap: () => CategoriesScreen.open(context),
              ),
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Data & Backup',
                subtitle: 'Export JSON, validate & restore',
                onTap: () => DataManagementScreen.open(context),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          _SettingsGroup(
            title: 'About & Account',
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Account Profile',
                subtitle: currentUser?.fullName ?? 'Manage name',
                onTap: () =>
                    _editProfile(context, ref, currentUser?.fullName ?? ''),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About DueMate',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: () => AboutScreen.open(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Log out of your account'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                        'Are you sure you want to log out of DueMate?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authServiceProvider).signOut();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update your display name:'),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newName = nameController.text.trim();
              Navigator.pop(ctx);
              final result = await ref
                  .read(authServiceProvider)
                  .updateProfile(fullName: newName);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isSuccess
                        ? 'Profile updated'
                        : (result.error ?? 'Failed to update profile'),
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _managePhoto(
    BuildContext context,
    WidgetRef ref,
    String? currentPhoto,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, color: scheme.primary),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Profile Photo',
                      style: AppTextStyles.title,
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(sheetContext).pop('gallery'),
              ),
              if (currentPhoto != null && currentPhoto.isNotEmpty)
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop('remove'),
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(sheetContext).pop('cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'gallery' && context.mounted) {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (picked != null && context.mounted) {
          final result = await ref
              .read(authServiceProvider)
              .updateProfilePhoto(picked.path);
          if (context.mounted) {
            if (result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo updated')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.error ?? 'Failed to update photo'),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open image picker.')),
          );
        }
      }
    } else if (choice == 'remove' && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove profile photo?'),
          content: const Text(
            'Your avatar will revert to your name initial.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        final result = await ref
            .read(authServiceProvider)
            .updateProfilePhoto(null);
        if (context.mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo removed')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error ?? 'Failed to remove photo'),
              ),
            );
          }
        }
      }
    }
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Follow system',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.userName,
    required this.userEmail,
    this.photoUrl,
    this.onEdit,
    this.onChangePhoto,
  });

  final String userName;
  final String userEmail;
  final String? photoUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePhoto;

  ImageProvider? _resolveImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageProvider = _resolveImageProvider(photoUrl);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Change profile photo',
            child: InkWell(
              onTap: onChangePhoto,
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.primary,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.title.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: scheme.onPrimaryContainer),
              tooltip: 'Edit name',
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.lg,
        horizontal: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headline),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacing.xs, bottom: Spacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: scheme.outline),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22),
      title: Text(title, style: AppTextStyles.body),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
