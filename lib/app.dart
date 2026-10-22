import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_permission_coordinator.dart';
import 'core/services/app_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_x.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/tasks/task_details_screen.dart';
import 'features/tasks/widgets/alarm_screen.dart';
import 'models/enums.dart';
import 'models/user_settings.dart';
import 'providers/auth_provider.dart';
import 'providers/core_providers.dart';
import 'providers/settings_provider.dart';

/// Root widget for DueMate: theme, auth gate, onboarding gate, and deep-links.
class DueMateApp extends ConsumerStatefulWidget {
  const DueMateApp({super.key});

  @override
  ConsumerState<DueMateApp> createState() => _DueMateAppState();
}

class _DueMateAppState extends ConsumerState<DueMateApp>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<void>>? _bootstrapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForNotificationTaps();
  }

  @override
  void dispose() {
    _bootstrapSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderServiceProvider).processDueNotifications();
      ref.read(notificationServiceProvider).refreshPermissions().then((status) {
        if (status.notificationsGranted) {
          NotificationPermissionCoordinator.setPreviouslyDenied(false);
        }
      });
    }
  }

  void _listenForNotificationTaps() {
    final service = ref.read(notificationServiceProvider);

    service.onNotificationPayload.listen((payload) {
      _openFromNotification(payload.taskId, isAlarm: payload.kind == 'alarm');
    });

    _bootstrapSub = ref.listenManual(appBootstrapProvider, (previous, next) {
      if (next is AsyncData && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final payload = service.takeLaunchPayload();
          if (payload != null) {
            _openFromNotification(
              payload.taskId,
              isAlarm: payload.kind == 'alarm',
            );
          } else {
            final taskId = service.takeLaunchTask();
            if (taskId != null) _openFromNotification(taskId);
          }
        });
        _bootstrapSub?.close();
        _bootstrapSub = null;
      }
    });
  }

  Future<void> _openFromNotification(
    String taskId, {
    bool isAlarm = false,
  }) async {
    if (!mounted || taskId.isEmpty) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (isAlarm) {
      await AlarmScreen.show(navigator.context, taskId);
    } else {
      final task = await ref.read(taskRepositoryProvider).getById(taskId);
      if (!mounted) return;
      if (task != null && task.alarmType == AlarmType.alarmScreen) {
        await AlarmScreen.show(navigator.context, taskId);
      } else {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailsScreen(taskId: taskId),
          ),
        );
      }
    }
  }

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final bootstrap = ref.watch(appBootstrapProvider);

    final settings = ref.watch(settingsProvider).value;
    if (settings != null) {
      DateDisplay.configure(
        order: switch (settings.dateStyle) {
          DateStyle.dayMonth => AppDateOrder.dayMonth,
          DateStyle.monthDay => AppDateOrder.monthDay,
        },
        use24Hour: settings.use24HourTime,
      );
    }

    return MaterialApp(
      title: 'DueMate',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: _Gate(bootstrap: bootstrap),
    );
  }
}

void _noop() {}

/// Auth Gate: Splash while bootstrapping/authenticating -> Login or Onboarding -> App Shell
class _Gate extends ConsumerWidget {
  const _Gate({required this.bootstrap});

  final AsyncValue<void> bootstrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final authAsync = ref.watch(authStateProvider);

    if (bootstrap.isLoading || settingsAsync.isLoading || authAsync.isLoading) {
      return const _Splash();
    }

    final currentUser =
        authAsync.value ?? ref.watch(authServiceProvider).currentUser;

    if (currentUser == null) {
      return const LoginScreen();
    }

    final settings = settingsAsync.value ?? const UserSettings();

    if (!settings.onboardingComplete) {
      return const OnboardingScreen(onFinished: _noop);
    }

    return const AppShell();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: scheme.onPrimary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text('DueMate', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Never miss what matters.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
