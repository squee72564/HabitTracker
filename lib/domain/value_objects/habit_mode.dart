enum HabitMode {
  positive('positive'),
  negative('negative');

  const HabitMode(this.storageValue);

  final String storageValue;

  static HabitMode fromStorageValue(final String value) {
    for (final HabitMode mode in HabitMode.values) {
      if (mode.storageValue == value) {
        return mode;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown habit mode.');
  }
}
