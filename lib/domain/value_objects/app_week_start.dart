enum AppWeekStart {
  monday('monday'),
  sunday('sunday');

  const AppWeekStart(this.storageValue);

  final String storageValue;

  static AppWeekStart fromStorageValue(final String value) {
    for (final AppWeekStart weekStart in AppWeekStart.values) {
      if (weekStart.storageValue == value) {
        return weekStart;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown week start value.');
  }
}
