enum HabitEventType {
  complete('complete'),
  relapse('relapse');

  const HabitEventType(this.storageValue);

  final String storageValue;

  static HabitEventType fromStorageValue(final String value) {
    for (final HabitEventType type in HabitEventType.values) {
      if (type.storageValue == value) {
        return type;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown habit event type.');
  }
}
