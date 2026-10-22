import 'package:duemate/core/utils/recurrence_calculator.dart';
import 'package:duemate/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDays / serializeDays', () {
    test('round-trips a set of weekdays', () {
      final csv = RecurrenceCalculator.serializeDays([5, 1, 3]);
      expect(csv, '1,3,5');
      expect(RecurrenceCalculator.parseDays(csv), [1, 3, 5]);
    });

    test('ignores out-of-range and non-numeric values', () {
      expect(RecurrenceCalculator.parseDays('1,9,foo,0,7'), [1, 7]);
      expect(RecurrenceCalculator.parseDays(null), isEmpty);
      expect(RecurrenceCalculator.parseDays('  '), isEmpty);
    });

    test('de-duplicates days', () {
      expect(RecurrenceCalculator.parseDays('2,2,2'), [2]);
    });
  });

  group('nextOccurrence', () {
    test('daily adds exactly one day', () {
      final from = DateTime(2026, 10, 8, 9, 0);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.daily,
        recurrenceDays: null,
        from: from,
      );
      expect(next, DateTime(2026, 10, 9, 9, 0));
    });

    test('weekly adds exactly seven days', () {
      final from = DateTime(2026, 10, 5, 9, 0); // Monday
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.weekly,
        recurrenceDays: null,
        from: from,
      );
      expect(next, DateTime(2026, 10, 12, 9, 0));
      expect(next!.weekday, DateTime.monday);
    });

    test('monthly advances one month preserving the day', () {
      final from = DateTime(2026, 10, 15, 9, 0);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.monthly,
        recurrenceDays: null,
        from: from,
      );
      expect(next, DateTime(2026, 11, 15, 9, 0));
    });

    test('monthly clamps to the last valid day', () {
      final from = DateTime(2026, 1, 31, 9, 0);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.monthly,
        recurrenceDays: null,
        from: from,
      );
      expect(next, DateTime(2026, 2, 28, 9, 0));
    });

    test('monthly rolls the year over', () {
      final from = DateTime(2026, 12, 10, 9, 0);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.monthly,
        recurrenceDays: null,
        from: from,
      );
      expect(next, DateTime(2027, 1, 10, 9, 0));
    });

    test('custom weekly picks the next selected weekday', () {
      // 2026-10-08 is a Thursday (ISO 4). Selected: Monday (1) and Friday (5).
      final from = DateTime(2026, 10, 8, 9, 0);
      expect(from.weekday, DateTime.thursday);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.customWeekly,
        recurrenceDays: '1,5',
        from: from,
      );
      expect(next!.weekday, DateTime.friday);
      expect(next, DateTime(2026, 10, 9, 9, 0));
    });

    test('custom weekly wraps to the following week', () {
      // From a Friday, the next Monday is three days later.
      final from = DateTime(2026, 10, 9, 9, 0);
      final next = RecurrenceCalculator.nextOccurrence(
        type: RecurrenceType.customWeekly,
        recurrenceDays: '1',
        from: from,
      );
      expect(next, DateTime(2026, 10, 12, 9, 0));
    });

    test('none returns null', () {
      expect(
        RecurrenceCalculator.nextOccurrence(
          type: RecurrenceType.none,
          recurrenceDays: null,
          from: DateTime(2026),
        ),
        isNull,
      );
    });

    test('custom weekly with no days returns null', () {
      expect(
        RecurrenceCalculator.nextOccurrence(
          type: RecurrenceType.customWeekly,
          recurrenceDays: '',
          from: DateTime(2026, 10, 8),
        ),
        isNull,
      );
    });
  });

  group('validate', () {
    test('none is always valid', () {
      expect(
        RecurrenceCalculator.validate(
          type: RecurrenceType.none,
          recurrenceDays: null,
        ),
        isNull,
      );
    });

    test('repeating without a deadline is rejected', () {
      expect(
        RecurrenceCalculator.validate(
          type: RecurrenceType.daily,
          recurrenceDays: null,
          deadline: null,
        ),
        isNotNull,
      );
    });

    test('custom weekly without days is rejected', () {
      expect(
        RecurrenceCalculator.validate(
          type: RecurrenceType.customWeekly,
          recurrenceDays: '',
          deadline: DateTime(2026, 10, 8),
        ),
        isNotNull,
      );
    });

    test('valid custom weekly passes', () {
      expect(
        RecurrenceCalculator.validate(
          type: RecurrenceType.customWeekly,
          recurrenceDays: '1,3,5',
          deadline: DateTime(2026, 10, 8),
        ),
        isNull,
      );
    });
  });
}
