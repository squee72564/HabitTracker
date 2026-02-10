import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  LocalReminderNotificationScheduler({
    final FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _isInitialized = false;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription =
      'Daily reminders for configured habits.';

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimezone();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        );

    await _plugin.initialize(settings: initializationSettings);
    _isInitialized = true;
  }

  @override
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return true;
    }
    return await androidPlugin.areNotificationsEnabled() ?? true;
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    await initialize();
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return true;
    }
    return await androidPlugin.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDailyReminder({
    required final String habitId,
    required final String habitName,
    required final int reminderTimeMinutes,
  }) async {
    await initialize();
    final int hour = reminderTimeMinutes ~/ 60;
    final int minute = reminderTimeMinutes % 60;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduleAt.isAfter(now)) {
      scheduleAt = scheduleAt.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationIdForHabit(habitId),
      title: 'Habit reminder',
      body: 'Time to check in: $habitName',
      scheduledDate: scheduleAt,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: habitId,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelReminder({required final String habitId}) async {
    await initialize();
    await _plugin.cancel(id: _notificationIdForHabit(habitId));
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }
}

int _notificationIdForHabit(final String habitId) {
  int hash = 0;
  for (final int codeUnit in habitId.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return hash;
}
