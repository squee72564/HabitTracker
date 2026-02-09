import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('local day key helpers', () {
    test('formats local day key as YYYY-MM-DD', () {
      final String localDayKey = toLocalDayKey(DateTime(2026, 2, 9, 14, 30));

      expect(localDayKey, '2026-02-09');
      expect(isValidLocalDayKey(localDayKey), isTrue);
    });

    test('changes day key across midnight boundary', () {
      final String beforeMidnight = toLocalDayKey(DateTime(2026, 2, 9, 23, 59));
      final String afterMidnight = toLocalDayKey(DateTime(2026, 2, 10, 0, 0));

      expect(beforeMidnight, '2026-02-09');
      expect(afterMidnight, '2026-02-10');
    });

    test('uses persisted timezone offset for historical day bucketing', () {
      final DateTime occurredAtUtc = DateTime.utc(2026, 2, 9, 23, 30);

      expect(
        localDayKeyFromUtcAndOffset(
          occurredAtUtc: occurredAtUtc,
          tzOffsetMinutesAtEvent: 120,
        ),
        '2026-02-10',
      );
      expect(
        localDayKeyFromUtcAndOffset(
          occurredAtUtc: occurredAtUtc,
          tzOffsetMinutesAtEvent: -300,
        ),
        '2026-02-09',
      );
    });

    test('converts UTC input to device local calendar day', () {
      final DateTime utcInstant = DateTime.utc(2026, 2, 9, 3, 30);
      final DateTime localInstant = utcInstant.toLocal();
      final String expectedDayKey = _formatDayKey(localInstant);

      expect(toLocalDayKey(utcInstant), expectedDayKey);
    });
  });

  group('timezone offset helper', () {
    test('captures timezone offset minutes from local instant', () {
      final DateTime localNow = DateTime.now();

      expect(
        captureTzOffsetMinutesAtEvent(localNow),
        localNow.timeZoneOffset.inMinutes,
      );
    });
  });
}

String _formatDayKey(final DateTime dateTime) {
  final String year = dateTime.year.toString().padLeft(4, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
