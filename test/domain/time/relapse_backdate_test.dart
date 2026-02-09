import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('resolveBackdatedRelapseLocalDateTime', () {
    test('accepts dates within the last 7 days and keeps local time', () {
      final DateTime nowLocal = DateTime(2026, 2, 15, 21, 30, 15, 123, 456);
      final DateTime selectedDate = DateTime(2026, 2, 8);

      final DateTime resolved = resolveBackdatedRelapseLocalDateTime(
        nowLocal: nowLocal,
        selectedLocalDate: selectedDate,
      );

      expect(resolved.year, 2026);
      expect(resolved.month, 2);
      expect(resolved.day, 8);
      expect(resolved.hour, 21);
      expect(resolved.minute, 30);
      expect(resolved.second, 15);
      expect(resolved.millisecond, 123);
      expect(resolved.microsecond, 456);
    });

    test('throws when selected date is today', () {
      final DateTime nowLocal = DateTime(2026, 2, 15, 9, 30);

      expect(
        () => resolveBackdatedRelapseLocalDateTime(
          nowLocal: nowLocal,
          selectedLocalDate: DateTime(2026, 2, 15),
        ),
        throwsA(isA<RelapseBackdateOutOfRangeException>()),
      );
    });

    test('throws when selected date is older than 7 days', () {
      final DateTime nowLocal = DateTime(2026, 2, 15, 9, 30);

      expect(
        () => resolveBackdatedRelapseLocalDateTime(
          nowLocal: nowLocal,
          selectedLocalDate: DateTime(2026, 2, 7),
        ),
        throwsA(isA<RelapseBackdateOutOfRangeException>()),
      );
    });
  });
}
