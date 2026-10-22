import 'package:intl/intl.dart';

/// Timezone-safe date helpers.
///
/// All persisted `DateTime`s are stored as UTC by the database layer. The
/// functions here deliberately operate on **local** time for display because
/// "due today" is a local-calendar concept. Callers should pass local
/// DateTimes; `_local()` normalises defensively.
///
/// We never compare formatted strings — comparisons always use the underlying
/// instant or a calendar comparison of (y, m, d).
extension DateX on DateTime {
  DateTime _local() => isUtc ? toLocal() : this;

  /// Start of the day (00:00:00.000) in local time.
  DateTime get startOfDay {
    final d = _local();
    return DateTime(d.year, d.month, d.day);
  }

  /// End of the day (23:59:59.999) in local time.
  DateTime get endOfDay => startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  DateTime get startOfMonth => DateTime(_local().year, _local().month);

  DateTime get endOfMonth =>
      DateTime(_local().year, _local().month + 1, 0, 23, 59, 59, 999);

  DateTime get startOfWeek {
    // ISO week: Monday first.
    final d = _local();
    final monday = d.subtract(Duration(days: d.weekday - DateTime.monday));
    return monday.startOfDay;
  }

  DateTime get endOfWeek => startOfWeek
      .add(const Duration(days: 7))
      .subtract(const Duration(milliseconds: 1));

  bool isSameDay(DateTime other) {
    final a = _local();
    final b = other._local();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isToday() => isSameDay(DateTime.now());

  bool isTomorrow() => isSameDay(DateTime.now().add(const Duration(days: 1)));

  bool isYesterday() =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  bool isPast() => _local().isBefore(DateTime.now());

  bool isFuture() => _local().isAfter(DateTime.now());

  /// Whole calendar days between now and this date (negative if in the past).
  int daysFromToday() {
    final now = DateTime.now().startOfDay;
    final target = startOfDay;
    return target.difference(now).inDays;
  }
}

/// Calendar helpers that work on nullable deadlines.
class DateUtilsX {
  const DateUtilsX._();

  /// Combines a date (y/m/d) with a time (h/m) into one local DateTime.
  static DateTime combine(DateTime date, DateTime time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  /// Guards against absurd values coming from pickers.
  static DateTime clampYear(DateTime value) {
    if (value.year < 1970) return DateTime(1970, 1, 1);
    if (value.year > 2200) return DateTime(2200, 1, 1);
    return value;
  }
}

/// Whether dates read "10 Oct" (day first) or "Oct 10" (month first).
enum AppDateOrder { dayMonth, monthDay }

/// Process-wide holder for the active date/time display preferences.
///
/// Updated whenever settings load or change (see `settings_provider.dart`), so
/// [AppDateFormat] can stay a set of plain static functions while still
/// honouring the user's Date/Time format choices.
class DateDisplay {
  const DateDisplay._();

  static AppDateOrder order = AppDateOrder.dayMonth;
  static bool use24Hour = false;

  static void configure({
    required AppDateOrder order,
    required bool use24Hour,
  }) {
    DateDisplay.order = order;
    DateDisplay.use24Hour = use24Hour;
  }

  static String get _dayMonth =>
      order == AppDateOrder.dayMonth ? 'd MMM' : 'MMM d';
  static String get _dayMonthYear =>
      order == AppDateOrder.dayMonth ? 'd MMM yyyy' : 'MMM d, yyyy';
  static String get _weekdayDayMonth =>
      order == AppDateOrder.dayMonth ? 'EEE, d MMM yyyy' : 'EEE, MMM d, yyyy';
  static String get _timePattern => use24Hour ? 'HH:mm' : 'h:mm a';
}

/// Human-friendly formatters that respect [DateDisplay] preferences.
class AppDateFormat {
  const AppDateFormat._();

  static String time(DateTime dt) =>
      DateFormat(DateDisplay._timePattern).format(dt.toLocal());

  static String day(DateTime dt) =>
      DateFormat(DateDisplay._dayMonth).format(dt.toLocal());

  static String dayWithYear(DateTime dt) =>
      DateFormat(DateDisplay._dayMonthYear).format(dt.toLocal());

  static String weekday(DateTime dt) => DateFormat('EEE').format(dt.toLocal());

  static String fullDate(DateTime dt) =>
      DateFormat(DateDisplay._weekdayDayMonth).format(dt.toLocal());

  static String monthTitle(DateTime dt) =>
      DateFormat('MMMM yyyy').format(dt.toLocal());

  static String dateAndTime(DateTime dt) {
    final local = dt.toLocal();
    return '${DateFormat(DateDisplay._dayMonthYear).format(local)} • '
        '${DateFormat(DateDisplay._timePattern).format(local)}';
  }

  /// "Today", "Tomorrow", "Yesterday", a weekday for the next 6 days, or an
  /// explicit date.
  static String relativeDay(DateTime dt) {
    final local = dt.toLocal();
    if (local.isToday()) return 'Today';
    if (local.isTomorrow()) return 'Tomorrow';
    if (local.isYesterday()) return 'Yesterday';
    final diff = local.daysFromToday();
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(local);
    if (diff < -1 && diff > -7) return DateFormat('EEEE').format(local);
    return day(local);
  }

  /// "Today • 7:00 PM"
  static String relativeDayTime(DateTime dt) =>
      '${relativeDay(dt)} • ${time(dt)}';
}

/// Formats a [Duration] as a compact, human countdown.
class DurationFormat {
  const DurationFormat._();

  /// "2d 4h", "5h 20m", "45m", "30s".
  static String compact(Duration d) {
    final abs = d.abs();
    if (abs.inDays >= 1) {
      final days = abs.inDays;
      final hours = abs.inHours - days * 24;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
    if (abs.inHours >= 1) {
      final hours = abs.inHours;
      final minutes = abs.inMinutes - hours * 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    if (abs.inMinutes >= 1) {
      return '${abs.inMinutes}m';
    }
    return '${abs.inSeconds}s';
  }

  /// "2 days", "5 hours", "45 minutes" — for sentences.
  static String verbose(Duration d) {
    final abs = d.abs();
    if (abs.inDays >= 1) {
      final days = abs.inDays;
      return days == 1 ? '1 day' : '$days days';
    }
    if (abs.inHours >= 1) {
      final hours = abs.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    if (abs.inMinutes >= 1) {
      final minutes = abs.inMinutes;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
    return 'less than a minute';
  }
}
