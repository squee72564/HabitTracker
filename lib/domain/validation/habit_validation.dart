import 'package:habit_tracker/domain/value_objects/domain_constraints.dart';

enum HabitNameValidationError { empty, tooLong }

enum HabitNoteValidationError { tooLong }

class HabitValidation {
  const HabitValidation._();

  static HabitNameValidationError? validateName(final String name) {
    final String normalizedName = normalizeName(name);
    if (normalizedName.length < DomainConstraints.habitNameMinLength) {
      return HabitNameValidationError.empty;
    }
    if (normalizedName.length > DomainConstraints.habitNameMaxLength) {
      return HabitNameValidationError.tooLong;
    }
    return null;
  }

  static HabitNoteValidationError? validateNote(final String? note) {
    if (note == null) {
      return null;
    }
    if (note.length > DomainConstraints.habitNoteMaxLength) {
      return HabitNoteValidationError.tooLong;
    }
    return null;
  }

  static bool hasCaseInsensitiveDuplicateName({
    required final String candidateName,
    required final Iterable<String> existingNames,
    final String? currentName,
  }) {
    final String normalizedCandidate = normalizeName(candidateName);
    if (normalizedCandidate.isEmpty) {
      return false;
    }

    final String? normalizedCurrent = currentName == null
        ? null
        : normalizeName(currentName);

    for (final String existingName in existingNames) {
      final String normalizedExistingName = normalizeName(existingName);
      final bool isCurrentName =
          normalizedCurrent != null &&
          normalizedExistingName == normalizedCurrent;
      if (!isCurrentName && normalizedExistingName == normalizedCandidate) {
        return true;
      }
    }
    return false;
  }

  static String normalizeName(final String name) {
    return name.trim().toLowerCase();
  }
}
