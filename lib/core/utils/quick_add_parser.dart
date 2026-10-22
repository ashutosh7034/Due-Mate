import '../../models/enums.dart';

/// Result of parsing a quick-add phrase.
class QuickAddResult {
  const QuickAddResult({
    required this.title,
    this.deadline,
    this.priority,
    this.matchedDate = false,
    this.matchedTime = false,
  });

  final String title;
  final DateTime? deadline;
  final Priority? priority;
  final bool matchedDate;
  final bool matchedTime;

  bool get hasDeadline => deadline != null;

  /// Whether any structured part was understood.
  bool get isStructured => matchedDate || matchedTime || priority != null;
}

/// A deliberately small, dependency-free natural-language parser for the
/// quick-add field.
///
/// It is intentionally conservative: it only extracts patterns it is confident
/// about and leaves everything else in the title. The UI always lets the user
/// review the parsed result before saving, so a wrong guess is never silent.
class QuickAddParser {
  const QuickAddParser._();

  static final RegExp _timeRegex = RegExp(
    r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  );
  static final RegExp _time24Regex = RegExp(
    r'\bat\s+(\d{1,2}):(\d{2})\b',
    caseSensitive: false,
  );
  static final RegExp _inDurationRegex = RegExp(
    r'\bin\s+(\d{1,3})\s*(minute|min|hour|hr|day|week)s?\b',
    caseSensitive: false,
  );
  static final RegExp _dayMonthRegex = RegExp(
    r'\b(?:on\s+)?(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b',
    caseSensitive: false,
  );
  static final RegExp _slashDateRegex = RegExp(
    r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b',
  );
  static final RegExp _nextWeekdayRegex = RegExp(
    r'\b(?:next|on|this)\s+(mon|tue|wed|thu|fri|sat|sun)[a-z]*\b',
    caseSensitive: false,
  );
  static final RegExp _urgentRegex = RegExp(
    r'(!{1,3})|\b(urgent|asap|critical)\b',
    caseSensitive: false,
  );
  static final RegExp _highRegex = RegExp(
    r'\b(high priority|important)\b',
    caseSensitive: false,
  );
  static final RegExp _lowRegex = RegExp(
    r'\b(low priority|whenever|someday)\b',
    caseSensitive: false,
  );

  static const Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static const Map<String, int> _weekdays = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  /// Parses [input]. [now] is injectable for deterministic tests.
  static QuickAddResult parse(String input, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    var working = ' $input ';
    var matchedDate = false;
    var matchedTime = false;
    Priority? priority;

    DateTime? date;
    int? hour;
    int? minute;

    // Priority tokens.
    if (_urgentRegex.hasMatch(working)) {
      priority = Priority.urgent;
      working = working
          .replaceAll(_urgentRegex, ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ');
    } else if (_highRegex.hasMatch(working)) {
      priority = Priority.high;
      working = working.replaceAll(_highRegex, ' ');
    } else if (_lowRegex.hasMatch(working)) {
      priority = Priority.low;
      working = working.replaceAll(_lowRegex, ' ');
    }

    // Relative date words first, so "tomorrow at 7pm" gets both parts.
    final lower = working.toLowerCase();
    if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      date = _dayAt(clock, 1);
      matchedDate = true;
      working = _remove(working, RegExp(r'\btomorrow\b', caseSensitive: false));
    } else if (RegExp(r'\btoday\b').hasMatch(lower)) {
      date = _dayAt(clock, 0);
      matchedDate = true;
      working = _remove(working, RegExp(r'\btoday\b', caseSensitive: false));
    } else if (RegExp(r'\btonight\b').hasMatch(lower)) {
      date = _dayAt(clock, 0);
      hour = 20;
      minute = 0;
      matchedDate = true;
      matchedTime = true;
      working = _remove(working, RegExp(r'\btonight\b', caseSensitive: false));
    } else if (RegExp(r'\bnext week\b').hasMatch(lower)) {
      date = _dayAt(clock, 7);
      matchedDate = true;
      working = _remove(
        working,
        RegExp(r'\bnext week\b', caseSensitive: false),
      );
    }

    // "in 3 days" / "in 2 hours".
    final inMatch = _inDurationRegex.firstMatch(working);
    if (inMatch != null) {
      final amount = int.tryParse(inMatch.group(1) ?? '') ?? 0;
      final unit = (inMatch.group(2) ?? '').toLowerCase();
      final offset = unit.startsWith('min')
          ? Duration(minutes: amount)
          : unit.startsWith('hour') || unit.startsWith('hr')
          ? Duration(hours: amount)
          : unit.startsWith('day')
          ? Duration(days: amount)
          : Duration(days: amount * 7);
      final target = clock.add(offset);
      date = target;
      if (unit.startsWith('min') ||
          unit.startsWith('hour') ||
          unit.startsWith('hr')) {
        hour = target.hour;
        minute = target.minute;
        matchedTime = true;
      }
      matchedDate = true;
      working = _remove(working, _inDurationRegex);
    }

    // Explicit day + month.
    if (!matchedDate) {
      final dm = _dayMonthRegex.firstMatch(working);
      if (dm != null) {
        final day = int.tryParse(dm.group(1) ?? '');
        final month = _months[(dm.group(2) ?? '').toLowerCase()];
        if (day != null && month != null) {
          final candidate = DateTime(clock.year, month, day);
          date = candidate.isBefore(_dayAt(clock, 0))
              ? DateTime(clock.year + 1, month, day)
              : candidate;
          matchedDate = true;
          working = _remove(working, _dayMonthRegex);
        }
      }
    }

    // Numeric date d/m.
    if (!matchedDate) {
      final slash = _slashDateRegex.firstMatch(working);
      if (slash != null) {
        final day = int.tryParse(slash.group(1) ?? '');
        final month = int.tryParse(slash.group(2) ?? '');
        if (day != null &&
            month != null &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          final candidate = DateTime(clock.year, month, day);
          date = candidate.isBefore(_dayAt(clock, 0))
              ? DateTime(clock.year + 1, month, day)
              : candidate;
          matchedDate = true;
          working = _remove(working, _slashDateRegex);
        }
      }
    }

    // Weekday names ("next monday", "on friday").
    if (!matchedDate) {
      final wd = _nextWeekdayRegex.firstMatch(working);
      if (wd != null) {
        final weekday = _weekdays[(wd.group(1) ?? '').toLowerCase()];
        if (weekday != null) {
          date = _nextWeekday(clock, weekday);
          matchedDate = true;
          working = _remove(working, _nextWeekdayRegex);
        }
      }
    }

    // Time of day words.
    if (!matchedTime) {
      if (RegExp(r'\bnoon\b', caseSensitive: false).hasMatch(working)) {
        hour = 12;
        minute = 0;
        matchedTime = true;
        working = _remove(working, RegExp(r'\bnoon\b', caseSensitive: false));
      } else if (RegExp(
        r'\bmidnight\b',
        caseSensitive: false,
      ).hasMatch(working)) {
        hour = 0;
        minute = 0;
        matchedTime = true;
        working = _remove(
          working,
          RegExp(r'\bmidnight\b', caseSensitive: false),
        );
      } else if (RegExp(
        r'\bmorning\b',
        caseSensitive: false,
      ).hasMatch(working)) {
        hour = 9;
        minute = 0;
        matchedTime = true;
        working = _remove(
          working,
          RegExp(r'\bmorning\b', caseSensitive: false),
        );
      } else if (RegExp(
        r'\bafternoon\b',
        caseSensitive: false,
      ).hasMatch(working)) {
        hour = 14;
        minute = 0;
        matchedTime = true;
        working = _remove(
          working,
          RegExp(r'\bafternoon\b', caseSensitive: false),
        );
      } else if (RegExp(
        r'\bevening\b',
        caseSensitive: false,
      ).hasMatch(working)) {
        hour = 19;
        minute = 0;
        matchedTime = true;
        working = _remove(
          working,
          RegExp(r'\bevening\b', caseSensitive: false),
        );
      }
    }

    // "7 pm" / "7:30pm".
    if (!matchedTime) {
      final ampm = _timeRegex.firstMatch(working);
      if (ampm != null) {
        var h = int.tryParse(ampm.group(1) ?? '') ?? 0;
        final m = int.tryParse(ampm.group(2) ?? '0') ?? 0;
        final isPm = (ampm.group(3) ?? '').toLowerCase() == 'pm';
        if (h >= 1 && h <= 12) {
          if (isPm && h != 12) h += 12;
          if (!isPm && h == 12) h = 0;
          hour = h;
          minute = m;
          matchedTime = true;
          working = _remove(working, _timeRegex);
        }
      }
    }

    // 24-hour "at 19:00".
    if (!matchedTime) {
      final t24 = _time24Regex.firstMatch(working);
      if (t24 != null) {
        final h = int.tryParse(t24.group(1) ?? '');
        final m = int.tryParse(t24.group(2) ?? '');
        if (h != null && h >= 0 && h <= 23 && m != null && m <= 59) {
          hour = h;
          minute = m;
          matchedTime = true;
          working = _remove(working, _time24Regex);
        }
      }
    }

    // Build the deadline.
    DateTime? deadline;
    if (date != null && matchedTime) {
      deadline = DateTime(
        date.year,
        date.month,
        date.day,
        hour ?? 9,
        minute ?? 0,
      );
    } else if (date != null) {
      // A date with no explicit time defaults to end of day.
      deadline = DateTime(date.year, date.month, date.day, 23, 59);
    } else if (matchedTime) {
      // A time with no date means today (or tomorrow if that time has passed).
      var candidate = DateTime(
        clock.year,
        clock.month,
        clock.day,
        hour ?? 9,
        minute ?? 0,
      );
      if (candidate.isBefore(clock)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      deadline = candidate;
    }

    final title = _cleanTitle(working);
    return QuickAddResult(
      title: title.isEmpty ? input.trim() : title,
      deadline: deadline,
      priority: priority,
      matchedDate: matchedDate,
      matchedTime: matchedTime,
    );
  }

  static String _cleanTitle(String value) {
    var result = value
        .replaceAll(RegExp(r'^\s+|\s+$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+([,.!?])'), r'$1')
        .replaceAll(RegExp(r'^[,.\-\s]+|[,.\-\s]+$'), '');
    return result.trim();
  }

  static String _remove(String value, RegExp pattern) =>
      value.replaceAll(pattern, ' ');

  static DateTime _dayAt(DateTime clock, int offset) =>
      DateTime(clock.year, clock.month, clock.day + offset);

  static DateTime _nextWeekday(DateTime clock, int weekday) {
    final base = DateTime(clock.year, clock.month, clock.day);
    var delta = (weekday - base.weekday) % 7;
    if (delta <= 0) delta += 7;
    return DateTime(base.year, base.month, base.day + delta);
  }
}
