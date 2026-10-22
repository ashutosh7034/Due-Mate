import '../../models/enums.dart';

/// Computes the next occurrence of a recurring task from its current deadline.
///
/// Pure and injectable-clock so it is unit-testable. Returns `null` when the
/// rule cannot produce a next date (e.g. custom weekly with no days selected).
class RecurrenceCalculator {
  const RecurrenceCalculator._();

  /// Parses the CSV `recurrenceDays` column into ISO weekday numbers
  /// (1 = Monday … 7 = Sunday), de-duplicated and sorted.
  static List<int> parseDays(String? csv) {
    if (csv == null || csv.trim().isEmpty) return const [];
    final days = <int>{};
    for (final part in csv.split(',')) {
      final n = int.tryParse(part.trim());
      if (n != null && n >= DateTime.monday && n <= DateTime.sunday) {
        days.add(n);
      }
    }
    final list = days.toList()..sort();
    return list;
  }

  /// Serialises ISO weekday numbers to the CSV stored in the database.
  static String serializeDays(Iterable<int> days) {
    final list =
        days
            .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
            .toSet()
            .toList()
          ..sort();
    return list.join(',');
  }

  /// Returns the next deadline strictly after [from].
  ///
  /// [from] is the current deadline (or `DateTime.now()` if the task has none).
  static DateTime? nextOccurrence({
    required RecurrenceType type,
    required String? recurrenceDays,
    required DateTime from,
  }) {
    switch (type) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return _addMonth(from);
      case RecurrenceType.customWeekly:
        return _nextCustomWeekly(from, parseDays(recurrenceDays));
    }
  }

  /// Adds one calendar month, clamping to the last valid day.
  ///
  /// 31 Jan → 28/29 Feb, 31 Mar → 30 Apr.
  static DateTime _addMonth(DateTime from) {
    final year = from.year;
    final month = from.month + 1;
    final targetYear = month > 12 ? year + 1 : year;
    final targetMonth = month > 12 ? 1 : month;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = from.day <= lastDay ? from.day : lastDay;
    return DateTime(
      targetYear,
      targetMonth,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
    );
  }

  /// Next date whose weekday is in [days], strictly after [from].
  static DateTime? _nextCustomWeekly(DateTime from, List<int> days) {
    if (days.isEmpty) return null;
    for (var offset = 1; offset <= 7; offset++) {
      final candidate = from.add(Duration(days: offset));
      if (days.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return null;
  }

  /// Validates a recurrence configuration, returning an error message or null.
  static String? validate({
    required RecurrenceType type,
    required String? recurrenceDays,
    DateTime? deadline,
  }) {
    if (type == RecurrenceType.none) return null;
    if (deadline == null) {
      return 'Set a deadline before choosing a repeat schedule.';
    }
    if (type == RecurrenceType.customWeekly &&
        parseDays(recurrenceDays).isEmpty) {
      return 'Select at least one day for a custom repeat.';
    }
    return null;
  }
}
