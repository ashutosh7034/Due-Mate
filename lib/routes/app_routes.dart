/// Central route names.
///
/// The app navigates imperatively, but every pushed route is tagged with one
/// of these names via [RouteSettings]. That keeps navigation auditable in one
/// place and gives notification deep-links a stable identifier.
class AppRoutes {
  const AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static const String taskEditor = '/task-editor';
  static const String taskDetails = '/task-details';
  static const String focusMode = '/focus';
  static const String categories = '/categories';
  static const String categoryEditor = '/category-editor';
  static const String about = '/about';
  static const String notificationSettings = '/notification-settings';
  static const String notificationDiagnostics = '/notification-diagnostics';
  static const String appearanceSettings = '/appearance-settings';
  static const String dataManagement = '/data-management';
}
