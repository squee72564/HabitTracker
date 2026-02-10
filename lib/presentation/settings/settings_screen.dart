import 'package:flutter/material.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.habitRepository,
    required this.appSettingsRepository,
    required this.habitReminderRepository,
    required this.notificationScheduler,
  });

  final HabitRepository habitRepository;
  final AppSettingsRepository appSettingsRepository;
  final HabitReminderRepository habitReminderRepository;
  final ReminderNotificationScheduler notificationScheduler;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _defaultReminderTimeMinutes = 1200;

  final AppLogger _logger = AppLogger.instance;
  AppSettings _settings = AppSettings.defaults;
  List<Habit> _habits = <Habit>[];
  Map<String, HabitReminder> _remindersByHabitId = <String, HabitReminder>{};
  Set<String> _busyHabitIds = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.notificationScheduler.initialize();
      final AppSettings settings = await widget.appSettingsRepository
          .loadSettings();
      final List<Habit> habits = await widget.habitRepository
          .listActiveHabits();
      final List<HabitReminder> reminders = await widget.habitReminderRepository
          .listReminders();
      if (!mounted) {
        return;
      }

      setState(() {
        _settings = settings;
        _habits = habits;
        _remindersByHabitId = <String, HabitReminder>{
          for (final HabitReminder reminder in reminders)
            reminder.habitId: reminder,
        };
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to load settings screen state.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load settings. Please try again.';
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(final BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadSettings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        Text('General', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                key: const Key('settings_week_start_switch'),
                title: const Text('Start week on Monday'),
                subtitle: Text(
                  _settings.weekStart == AppWeekStart.monday
                      ? 'Calendar and grid weeks start on Monday.'
                      : 'Calendar and grid weeks start on Sunday.',
                ),
                value: _settings.weekStart == AppWeekStart.monday,
                onChanged: (final bool value) {
                  _saveSettings(
                    _settings.copyWith(
                      weekStart: value
                          ? AppWeekStart.monday
                          : AppWeekStart.sunday,
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('settings_time_format_switch'),
                title: const Text('Use 24-hour time'),
                subtitle: Text(
                  _settings.timeFormat == AppTimeFormat.twentyFourHour
                      ? 'Reminder times are shown as 00:00.'
                      : 'Reminder times are shown as AM/PM.',
                ),
                value: _settings.timeFormat == AppTimeFormat.twentyFourHour,
                onChanged: (final bool value) {
                  _saveSettings(
                    _settings.copyWith(
                      timeFormat: value
                          ? AppTimeFormat.twentyFourHour
                          : AppTimeFormat.twelveHour,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: SwitchListTile(
            key: const Key('settings_global_reminders_switch'),
            title: const Text('Enable reminders'),
            subtitle: Text(
              _settings.remindersEnabled
                  ? 'Per-habit reminders can schedule notifications.'
                  : 'All reminders are paused. Per-habit preferences are preserved.',
            ),
            value: _settings.remindersEnabled,
            onChanged: _toggleGlobalReminders,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Configure a single daily reminder per habit.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_habits.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Create a habit first to configure reminders.'),
            ),
          )
        else
          ..._habits.map(_buildReminderCard),
      ],
    );
  }

  Widget _buildReminderCard(final Habit habit) {
    final HabitReminder reminder = _reminderForHabit(habit.id);
    final bool isBusy = _busyHabitIds.contains(habit.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  key: ValueKey<String>('settings_reminder_toggle_${habit.id}'),
                  value: reminder.isEnabled,
                  onChanged: isBusy
                      ? null
                      : (final bool enabled) =>
                            _toggleReminder(habit: habit, enabled: enabled),
                ),
              ],
            ),
            Text(
              _reminderLabel(reminder),
              key: ValueKey<String>('settings_reminder_label_${habit.id}'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey<String>(
                  'settings_reminder_time_button_${habit.id}',
                ),
                onPressed: isBusy || !reminder.isEnabled
                    ? null
                    : () => _pickReminderTime(habit: habit),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Change time'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings(final AppSettings updatedSettings) async {
    final AppSettings previous = _settings;
    setState(() {
      _settings = updatedSettings;
    });

    try {
      await widget.appSettingsRepository.saveSettings(updatedSettings);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to save app settings.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = previous;
      });
      _showSnackBar('Could not save settings.');
    }
  }

  HabitReminder _reminderForHabit(final String habitId) {
    return _remindersByHabitId[habitId] ??
        HabitReminder(
          habitId: habitId,
          isEnabled: false,
          reminderTimeMinutes: _defaultReminderTimeMinutes,
        );
  }

  Future<void> _toggleReminder({
    required final Habit habit,
    required final bool enabled,
  }) async {
    if (_busyHabitIds.contains(habit.id)) {
      return;
    }
    _setHabitBusy(habit.id, isBusy: true);

    try {
      final HabitReminder current = _reminderForHabit(habit.id);
      if (enabled && _settings.remindersEnabled) {
        final bool permissionGranted = await _ensurePermissionForReminders();
        if (!permissionGranted) {
          if (mounted) {
            _showSnackBar('Reminder not enabled. Notifications are disabled.');
          }
          return;
        }
      }

      final HabitReminder updated = current.copyWith(isEnabled: enabled);
      await widget.habitReminderRepository.saveReminder(updated);
      if (enabled && _settings.remindersEnabled) {
        await widget.notificationScheduler.scheduleDailyReminder(
          habitId: habit.id,
          habitName: habit.name,
          reminderTimeMinutes: updated.reminderTimeMinutes,
        );
      } else {
        await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _remindersByHabitId = <String, HabitReminder>{
          ..._remindersByHabitId,
          habit.id: updated,
        };
      });
      if (enabled && !_settings.remindersEnabled) {
        _showSnackBar(
          'Reminder preference saved. Enable global reminders to schedule it.',
        );
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to toggle reminder for habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackBar('Could not update reminder.');
      }
    } finally {
      _setHabitBusy(habit.id, isBusy: false);
    }
  }

  Future<void> _pickReminderTime({required final Habit habit}) async {
    if (_busyHabitIds.contains(habit.id)) {
      return;
    }

    final HabitReminder current = _reminderForHabit(habit.id);
    final TimeOfDay initialTime = TimeOfDay(
      hour: current.reminderHour,
      minute: current.reminderMinute,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) {
      return;
    }

    _setHabitBusy(habit.id, isBusy: true);
    try {
      final HabitReminder updated = current.copyWith(
        reminderTimeMinutes: picked.hour * 60 + picked.minute,
      );
      await widget.habitReminderRepository.saveReminder(updated);
      if (_settings.remindersEnabled) {
        await widget.notificationScheduler.scheduleDailyReminder(
          habitId: habit.id,
          habitName: habit.name,
          reminderTimeMinutes: updated.reminderTimeMinutes,
        );
      } else {
        await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _remindersByHabitId = <String, HabitReminder>{
          ..._remindersByHabitId,
          habit.id: updated,
        };
      });
      _showSnackBar(
        _settings.remindersEnabled
            ? 'Reminder time updated.'
            : 'Reminder time saved. Enable global reminders to apply it.',
      );
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to update reminder time for habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackBar('Could not update reminder time.');
      }
    } finally {
      _setHabitBusy(habit.id, isBusy: false);
    }
  }

  Future<void> _toggleGlobalReminders(final bool enabled) async {
    final AppSettings previous = _settings;
    final AppSettings updated = _settings.copyWith(remindersEnabled: enabled);
    setState(() {
      _settings = updated;
    });

    try {
      await widget.appSettingsRepository.saveSettings(updated);
      await _syncSchedulesForGlobalSetting(enabled: enabled);
      if (!mounted) {
        return;
      }
      _showSnackBar(
        enabled ? 'Global reminders enabled.' : 'Global reminders disabled.',
      );
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to toggle global reminders.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = previous;
      });
      _showSnackBar('Could not update reminder settings.');
    }
  }

  Future<void> _syncSchedulesForGlobalSetting({
    required final bool enabled,
  }) async {
    final Set<String> habitIdsToCancel = <String>{
      for (final Habit habit in _habits) habit.id,
      ..._remindersByHabitId.keys,
    };
    if (!enabled) {
      for (final String habitId in habitIdsToCancel) {
        await widget.notificationScheduler.cancelReminder(habitId: habitId);
      }
      return;
    }

    final Map<String, Habit> habitsById = <String, Habit>{
      for (final Habit habit in _habits) habit.id: habit,
    };
    for (final HabitReminder reminder in _remindersByHabitId.values) {
      final Habit? habit = habitsById[reminder.habitId];
      if (habit == null || !reminder.isEnabled) {
        await widget.notificationScheduler.cancelReminder(
          habitId: reminder.habitId,
        );
        continue;
      }
      await widget.notificationScheduler.scheduleDailyReminder(
        habitId: habit.id,
        habitName: habit.name,
        reminderTimeMinutes: reminder.reminderTimeMinutes,
      );
    }
  }

  void _setHabitBusy(final String habitId, {required final bool isBusy}) {
    if (!mounted) {
      return;
    }
    setState(() {
      final Set<String> updatedBusyHabitIds = <String>{..._busyHabitIds};
      if (isBusy) {
        updatedBusyHabitIds.add(habitId);
      } else {
        updatedBusyHabitIds.remove(habitId);
      }
      _busyHabitIds = updatedBusyHabitIds;
    });
  }

  Future<bool> _ensurePermissionForReminders() async {
    final bool notificationsAllowed = await widget.notificationScheduler
        .areNotificationsAllowed();
    if (notificationsAllowed) {
      return true;
    }

    final bool granted = await widget.notificationScheduler
        .requestNotificationsPermission();
    if (granted) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    await showDialog<void>(
      context: context,
      builder: (final BuildContext context) {
        return AlertDialog(
          key: const Key('settings_permission_fallback_dialog'),
          title: const Text('Notifications disabled'),
          content: const Text(
            'Enable notifications in Android system settings to use reminders.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return false;
  }

  String _formatReminderTime(final int minutesSinceMidnight) {
    final int hour = minutesSinceMidnight ~/ 60;
    final int minute = minutesSinceMidnight % 60;
    final String minuteText = minute.toString().padLeft(2, '0');

    if (_settings.timeFormat == AppTimeFormat.twentyFourHour) {
      return '${hour.toString().padLeft(2, '0')}:$minuteText';
    }

    final bool isPm = hour >= 12;
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = isPm ? 'PM' : 'AM';
    return '$hour12:$minuteText $period';
  }

  String _reminderLabel(final HabitReminder reminder) {
    if (!reminder.isEnabled) {
      return 'Reminder off';
    }
    final String formattedTime = _formatReminderTime(
      reminder.reminderTimeMinutes,
    );
    if (!_settings.remindersEnabled) {
      return 'Saved for $formattedTime (global reminders off)';
    }
    return 'Daily at $formattedTime';
  }

  void _showSnackBar(final String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
