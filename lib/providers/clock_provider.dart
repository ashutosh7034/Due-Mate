import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reactive, ticking clock provider that updates regularly (every 15 seconds)
/// and immediately upon app lifecycle resume.
///
/// Every screen and widget (Home, Tasks, Task Details, Calendar, Daily Summary, Alerts)
/// consuming this clock is guaranteed to show consistent, synchronized countdowns
/// with zero discrepancy.
class AppClockNotifier extends Notifier<DateTime> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  DateTime build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    // Tick every 15 seconds so remaining times ('in 5m', 'in 4m') stay fresh
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      state = DateTime.now();
    });

    return DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Instantly refresh clock as soon as the user returns to the app
      this.state = DateTime.now();
    }
  }

  /// Manually force a clock tick (e.g. on user refresh or task save).
  void refresh() {
    state = DateTime.now();
  }
}

/// The single source of truth for the current clock across the application.
final currentClockProvider = NotifierProvider<AppClockNotifier, DateTime>(
  AppClockNotifier.new,
);
