import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('name validation', () {
    test('rejects empty name after trimming whitespace', () {
      expect(
        HabitValidation.validateName('   '),
        HabitNameValidationError.empty,
      );
    });

    test('rejects names longer than max length', () {
      final String longName = List<String>.filled(
        DomainConstraints.habitNameMaxLength + 1,
        'a',
      ).join();

      expect(
        HabitValidation.validateName(longName),
        HabitNameValidationError.tooLong,
      );
    });

    test('accepts valid name within constraints', () {
      expect(HabitValidation.validateName(' Read books '), isNull);
    });
  });

  group('note validation', () {
    test('allows null and empty notes', () {
      expect(HabitValidation.validateNote(null), isNull);
      expect(HabitValidation.validateNote(''), isNull);
    });

    test('rejects notes longer than max length', () {
      final String longNote = List<String>.filled(
        DomainConstraints.habitNoteMaxLength + 1,
        'n',
      ).join();

      expect(
        HabitValidation.validateNote(longNote),
        HabitNoteValidationError.tooLong,
      );
    });
  });

  group('duplicate name checks', () {
    test('detects case-insensitive duplicates', () {
      expect(
        HabitValidation.hasCaseInsensitiveDuplicateName(
          candidateName: '  read  ',
          existingNames: <String>['Exercise', 'READ'],
        ),
        isTrue,
      );
    });

    test('ignores current name in edit flow', () {
      expect(
        HabitValidation.hasCaseInsensitiveDuplicateName(
          candidateName: 'Read',
          existingNames: <String>['Read', 'Exercise'],
          currentName: ' read ',
        ),
        isFalse,
      );
    });

    test('returns false when candidate name is unique', () {
      expect(
        HabitValidation.hasCaseInsensitiveDuplicateName(
          candidateName: 'Meditate',
          existingNames: <String>['Read', 'Exercise'],
        ),
        isFalse,
      );
    });
  });
}
