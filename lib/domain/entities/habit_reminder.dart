class HabitReminder {
  HabitReminder({
    required this.habitId,
    required this.isEnabled,
    required final int reminderTimeMinutes,
  }) : reminderTimeMinutes = _requireValidMinutes(reminderTimeMinutes);

  final String habitId;
  final bool isEnabled;
  final int reminderTimeMinutes;

  int get reminderHour => reminderTimeMinutes ~/ 60;
  int get reminderMinute => reminderTimeMinutes % 60;

  HabitReminder copyWith({
    final String? habitId,
    final bool? isEnabled,
    final int? reminderTimeMinutes,
  }) {
    return HabitReminder(
      habitId: habitId ?? this.habitId,
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
    );
  }

  static int _requireValidMinutes(final int value) {
    if (value < 0 || value > 1439) {
      throw ArgumentError.value(
        value,
        'reminderTimeMinutes',
        'reminderTimeMinutes must be between 0 and 1439.',
      );
    }
    return value;
  }
}
