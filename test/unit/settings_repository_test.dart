import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/user_settings.dart';
import 'package:duemate/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns sensible defaults on an empty database', () async {
    final settings = await repo.load();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.defaultReminderMinutes, 60);
    expect(settings.busyHoursEnabled, isFalse);
    expect(settings.onboardingComplete, isFalse);
  });

  test('save then load round-trips every field', () async {
    const settings = UserSettings(
      themeMode: ThemeMode.dark,
      notificationsEnabled: false,
      overdueRemindersEnabled: false,
      dailySummaryEnabled: false,
      upcomingAlertsEnabled: false,
      defaultReminderMinutes: 1440,
      busyHoursEnabled: true,
      busyStartHour: 8,
      busyEndHour: 18,
      weekStartsOnMonday: false,
      dateStyle: DateStyle.monthDay,
      use24HourTime: true,
      onboardingComplete: true,
    );

    await repo.save(settings);
    final loaded = await repo.load();

    expect(loaded, settings);
  });

  test('saving twice overwrites rather than duplicating keys', () async {
    await repo.save(const UserSettings(onboardingComplete: true));
    await repo.save(const UserSettings(onboardingComplete: false));

    final loaded = await repo.load();
    expect(loaded.onboardingComplete, isFalse);
  });

  test('the settings stream emits persisted values', () async {
    await repo.save(const UserSettings(themeMode: ThemeMode.light));
    final streamed = await repo.watch().first;
    expect(streamed.themeMode, ThemeMode.light);
  });
}
