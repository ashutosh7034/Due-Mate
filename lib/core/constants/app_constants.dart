/// App-wide constants for DueMate.
class AppConstants {
  const AppConstants._();

  static const String appName = 'DueMate';
  static const String tagline = 'Never miss what matters.';
  static const String appVersion = '1.0.0';

  /// Reserved id for the daily-summary notification, so it never collides
  /// with generated reminder ids (which start at 1000).
  static const int dailySummaryNotificationId = 1;

  /// A task is "due soon" within this window (used by the notification centre).
  static const Duration dueSoonWindow = Duration(hours: 24);
}
