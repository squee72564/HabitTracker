enum AppTimeFormat {
  twelveHour('12h'),
  twentyFourHour('24h');

  const AppTimeFormat(this.storageValue);

  final String storageValue;

  static AppTimeFormat fromStorageValue(final String value) {
    for (final AppTimeFormat timeFormat in AppTimeFormat.values) {
      if (timeFormat.storageValue == value) {
        return timeFormat;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown time format value.');
  }
}
