import 'dart:async';

import 'package:flutter/material.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/data/data.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/home/home_screen.dart';

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({
    super.key,
    this.habitRepository,
    this.habitEventRepository,
    this.appSettingsRepository,
    this.habitReminderRepository,
    this.notificationScheduler,
    this.database,
  });

  final HabitRepository? habitRepository;
  final HabitEventRepository? habitEventRepository;
  final AppSettingsRepository? appSettingsRepository;
  final HabitReminderRepository? habitReminderRepository;
  final ReminderNotificationScheduler? notificationScheduler;
  final AppDatabase? database;

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  final AppLogger _logger = AppLogger.instance;

  late final HabitRepository _habitRepository;
  late final HabitEventRepository _habitEventRepository;
  late final AppSettingsRepository _appSettingsRepository;
  late final HabitReminderRepository _habitReminderRepository;
  late final ReminderNotificationScheduler _notificationScheduler;
  AppDatabase? _ownedDatabase;

  @override
  void initState() {
    super.initState();
    if (widget.habitRepository != null) {
      if (widget.habitEventRepository == null) {
        throw ArgumentError(
          'habitEventRepository is required when habitRepository is provided.',
        );
      }
      _habitRepository = widget.habitRepository!;
      _habitEventRepository = widget.habitEventRepository!;
      _appSettingsRepository =
          widget.appSettingsRepository ?? _InMemoryAppSettingsRepository();
      _habitReminderRepository =
          widget.habitReminderRepository ?? _InMemoryHabitReminderRepository();
      _notificationScheduler =
          widget.notificationScheduler ?? _NoopReminderNotificationScheduler();
      return;
    }

    if (widget.database != null) {
      _habitRepository = DriftHabitRepository(widget.database!);
      _habitEventRepository = DriftHabitEventRepository(widget.database!);
      _appSettingsRepository =
          widget.appSettingsRepository ??
          DriftAppSettingsRepository(widget.database!);
      _habitReminderRepository =
          widget.habitReminderRepository ??
          DriftHabitReminderRepository(widget.database!);
      _notificationScheduler =
          widget.notificationScheduler ?? LocalReminderNotificationScheduler();
      unawaited(_syncConfiguredReminders());
      return;
    }

    _ownedDatabase = AppDatabase();
    _habitRepository = DriftHabitRepository(_ownedDatabase!);
    _habitEventRepository = DriftHabitEventRepository(_ownedDatabase!);
    _appSettingsRepository = DriftAppSettingsRepository(_ownedDatabase!);
    _habitReminderRepository = DriftHabitReminderRepository(_ownedDatabase!);
    _notificationScheduler = LocalReminderNotificationScheduler();
    unawaited(_syncConfiguredReminders());
  }

  Future<void> _syncConfiguredReminders() async {
    try {
      await _notificationScheduler.initialize();
      final bool notificationsAllowed = await _notificationScheduler
          .areNotificationsAllowed();
      if (!notificationsAllowed) {
        return;
      }

      final List<Habit> activeHabits = await _habitRepository
          .listActiveHabits();
      final Map<String, Habit> habitsById = <String, Habit>{
        for (final Habit habit in activeHabits) habit.id: habit,
      };
      final List<HabitReminder> reminders = await _habitReminderRepository
          .listReminders();
      for (final HabitReminder reminder in reminders) {
        final Habit? habit = habitsById[reminder.habitId];
        if (habit == null || !reminder.isEnabled) {
          await _notificationScheduler.cancelReminder(
            habitId: reminder.habitId,
          );
          continue;
        }
        await _notificationScheduler.scheduleDailyReminder(
          habitId: habit.id,
          habitName: habit.name,
          reminderTimeMinutes: reminder.reminderTimeMinutes,
        );
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to synchronize reminder notifications.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    final AppDatabase? database = _ownedDatabase;
    if (database != null) {
      unawaited(database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: AppTheme.light(),
      home: HomeScreen(
        habitRepository: _habitRepository,
        habitEventRepository: _habitEventRepository,
        appSettingsRepository: _appSettingsRepository,
        habitReminderRepository: _habitReminderRepository,
        notificationScheduler: _notificationScheduler,
      ),
    );
  }
}

class _InMemoryAppSettingsRepository implements AppSettingsRepository {
  AppSettings _settings = AppSettings.defaults;

  @override
  Future<AppSettings> loadSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(final AppSettings settings) async {
    _settings = settings;
  }
}

class _InMemoryHabitReminderRepository implements HabitReminderRepository {
  final Map<String, HabitReminder> _remindersByHabitId =
      <String, HabitReminder>{};

  @override
  Future<void> deleteReminderByHabitId(final String habitId) async {
    _remindersByHabitId.remove(habitId);
  }

  @override
  Future<HabitReminder?> findReminderByHabitId(final String habitId) async {
    return _remindersByHabitId[habitId];
  }

  @override
  Future<List<HabitReminder>> listReminders() async {
    return _remindersByHabitId.values.toList(growable: false);
  }

  @override
  Future<void> saveReminder(final HabitReminder reminder) async {
    _remindersByHabitId[reminder.habitId] = reminder;
  }
}

class _NoopReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  @override
  Future<bool> areNotificationsAllowed() async {
    return true;
  }

  @override
  Future<void> cancelReminder({required final String habitId}) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationsPermission() async {
    return true;
  }

  @override
  Future<void> scheduleDailyReminder({
    required final String habitId,
    required final String habitName,
    required final int reminderTimeMinutes,
  }) async {}
}
