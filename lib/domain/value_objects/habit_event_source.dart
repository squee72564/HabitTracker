enum HabitEventSource {
  manual('manual');

  const HabitEventSource(this.storageValue);

  final String storageValue;

  static HabitEventSource fromStorageValue(final String value) {
    for (final HabitEventSource source in HabitEventSource.values) {
      if (source.storageValue == value) {
        return source;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown habit event source.');
  }
}
