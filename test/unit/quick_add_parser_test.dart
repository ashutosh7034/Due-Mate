import 'package:duemate/core/utils/quick_add_parser.dart';
import 'package:duemate/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 8 October 2026, 10:00.
  final now = DateTime(2026, 10, 8, 10, 0);

  test('parses title, tomorrow and a 12-hour time', () {
    final result = QuickAddParser.parse(
      'Submit assignment tomorrow at 7 PM',
      now: now,
    );
    expect(result.title.toLowerCase(), contains('submit assignment'));
    expect(result.title.toLowerCase(), isNot(contains('tomorrow')));
    expect(result.matchedDate, isTrue);
    expect(result.matchedTime, isTrue);
    expect(result.deadline, DateTime(2026, 10, 9, 19, 0));
  });

  test('parses "today at 6pm"', () {
    final result = QuickAddParser.parse('Call mom today at 6pm', now: now);
    expect(result.deadline, DateTime(2026, 10, 8, 18, 0));
  });

  test('parses a bare time as today when still ahead', () {
    final result = QuickAddParser.parse('Standup at 11:30 am', now: now);
    expect(result.deadline, DateTime(2026, 10, 8, 11, 30));
  });

  test('rolls a passed bare time to tomorrow', () {
    final result = QuickAddParser.parse('Gym at 7 am', now: now);
    expect(result.deadline, DateTime(2026, 10, 9, 7, 0));
  });

  test('parses an explicit "in 3 hours"', () {
    final result = QuickAddParser.parse('Take break in 3 hours', now: now);
    expect(result.deadline, DateTime(2026, 10, 8, 13, 0));
  });

  test('parses day and month', () {
    final result = QuickAddParser.parse('Submit report on 15 Oct', now: now);
    expect(result.deadline!.month, 10);
    expect(result.deadline!.day, 15);
    // Defaults to end of day when no time is given.
    expect(result.deadline!.hour, 23);
    expect(result.deadline!.minute, 59);
  });

  test('parses a next weekday', () {
    // Next Monday from Wednesday 8 Oct is 12 Oct.
    final result = QuickAddParser.parse('Team sync next monday', now: now);
    expect(result.deadline!.year, 2026);
    expect(result.deadline!.month, 10);
    expect(result.deadline!.day, 12);
  });

  test('detects urgent priority from a bang', () {
    final result = QuickAddParser.parse('Finish tax filing!', now: now);
    expect(result.priority, Priority.urgent);
    expect(result.title.toLowerCase(), contains('tax'));
  });

  test('detects high priority from a phrase', () {
    final result = QuickAddParser.parse('Review PR high priority', now: now);
    expect(result.priority, Priority.high);
  });

  test('leaves plain text untouched', () {
    final result = QuickAddParser.parse('Read a book', now: now);
    expect(result.title, 'Read a book');
    expect(result.deadline, isNull);
    expect(result.priority, isNull);
    expect(result.isStructured, isFalse);
  });

  test('handles "tonight" as today at 8pm', () {
    final result = QuickAddParser.parse('Movie tonight', now: now);
    expect(result.deadline, DateTime(2026, 10, 8, 20, 0));
  });

  test('empty input yields an empty title result', () {
    final result = QuickAddParser.parse('', now: now);
    expect(result.title, isEmpty);
    expect(result.hasDeadline, isFalse);
  });
}
