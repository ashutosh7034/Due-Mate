import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_permission_coordinator.dart';
import '../../providers/core_providers.dart';
import '../calendar/calendar_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/tasks_screen.dart';
import 'widgets/shell_fab.dart';

/// The root shell holding the five primary destinations.
///
/// Uses an [IndexedStack] so each tab keeps its scroll position and state
/// while switching — important for a task app where users bounce around.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionCoordinator.checkAndPromptFirstLaunch(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            DashboardScreen(),
            TasksScreen(),
            CalendarScreen(),
            NotificationsScreen(),
            ProfileScreen(),
          ],
        ),
        floatingActionButton: ShellFab(
          // Quick-add is available on Home, Tasks and Calendar.
          visible: _index == 0 || _index == 1 || _index == 2,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: 'Tasks',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
