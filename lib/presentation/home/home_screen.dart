import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.habitRepository,
    required this.habitEventRepository,
    required this.appSettingsRepository,
    required this.habitReminderRepository,
    required this.notificationScheduler,
    this.clock = _systemNow,
  });

  final HabitRepository habitRepository;
  final HabitEventRepository habitEventRepository;
  final AppSettingsRepository appSettingsRepository;
  final HabitReminderRepository habitReminderRepository;
  final ReminderNotificationScheduler notificationScheduler;
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _defaultReminderTimeMinutes = 1200;

  final AppLogger _logger = AppLogger.instance;

  List<Habit> _habits = <Habit>[];
  Set<String> _completedTodayHabitIds = <String>{};
  Map<String, String> _streakLabelsByHabitId = <String, String>{};
  Map<String, List<HabitEvent>> _eventsByHabitId = <String, List<HabitEvent>>{};
  Set<String> _trackingHabitIds = <String>{};
  AppSettings _appSettings = AppSettings.defaults;
  late DateTime _visibleMonth;
  bool _isLoading = true;
  String? _errorMessage;
  int _eventIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _visibleMonth = toMonthStart(widget.clock());
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Future<List<Habit>> habitsFuture = widget.habitRepository
          .listActiveHabits();
      final Future<AppSettings> appSettingsFuture = widget.appSettingsRepository
          .loadSettings();
      final List<Habit> habits = await habitsFuture;
      final DateTime nowLocal = widget.clock();
      final _TrackingLoadResult trackingLoadResult =
          await _loadTrackingForHabits(habits: habits, nowLocal: nowLocal);
      final AppSettings appSettings = await appSettingsFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _habits = habits;
        _appSettings = appSettings;
        _completedTodayHabitIds = trackingLoadResult.completedTodayHabitIds;
        _streakLabelsByHabitId = trackingLoadResult.streakLabelsByHabitId;
        _eventsByHabitId = trackingLoadResult.eventsByHabitId;
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to load habits from repository.',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load habits. Please try again.';
      });
    }
  }

  Future<_TrackingLoadResult> _loadTrackingForHabits({
    required final List<Habit> habits,
    required final DateTime nowLocal,
  }) async {
    final List<MapEntry<String, _HabitTrackingSnapshot>> snapshots =
        await Future.wait<MapEntry<String, _HabitTrackingSnapshot>>(
          habits.map((final Habit habit) async {
            final _HabitTrackingSnapshot snapshot =
                await _buildTrackingSnapshot(habit: habit, nowLocal: nowLocal);
            return MapEntry<String, _HabitTrackingSnapshot>(habit.id, snapshot);
          }),
        );

    final Set<String> completedTodayHabitIds = <String>{};
    final Map<String, String> streakLabelsByHabitId = <String, String>{};
    final Map<String, List<HabitEvent>> eventsByHabitId =
        <String, List<HabitEvent>>{};
    for (final MapEntry<String, _HabitTrackingSnapshot> entry in snapshots) {
      final _HabitTrackingSnapshot snapshot = entry.value;
      if (snapshot.isCompletedToday) {
        completedTodayHabitIds.add(entry.key);
      }
      streakLabelsByHabitId[entry.key] = snapshot.streakLabel;
      eventsByHabitId[entry.key] = snapshot.events;
    }

    return _TrackingLoadResult(
      completedTodayHabitIds: completedTodayHabitIds,
      streakLabelsByHabitId: streakLabelsByHabitId,
      eventsByHabitId: eventsByHabitId,
    );
  }

  Future<_HabitTrackingSnapshot> _buildTrackingSnapshot({
    required final Habit habit,
    required final DateTime nowLocal,
  }) async {
    final List<HabitEvent> events = await widget.habitEventRepository
        .listEventsForHabit(habit.id);

    if (habit.mode == HabitMode.positive) {
      final String todayLocalDayKey = toLocalDayKey(nowLocal);
      final bool isCompletedToday = events.any(
        (final HabitEvent event) =>
            event.eventType == HabitEventType.complete &&
            event.localDayKey == todayLocalDayKey,
      );
      final int currentStreak = calculatePositiveCurrentStreak(
        events: events,
        referenceLocalDayKey: todayLocalDayKey,
      );
      return _HabitTrackingSnapshot(
        isCompletedToday: isCompletedToday,
        streakLabel: 'Streak: ${_formatDayCount(currentStreak)}',
        events: events,
      );
    }

    final DateTime nowUtc = nowLocal.toUtc();
    final Duration? currentStreak = calculateNegativeCurrentStreak(
      events: events,
      nowUtc: nowUtc,
    );
    if (currentStreak != null) {
      return _HabitTrackingSnapshot(
        isCompletedToday: false,
        streakLabel:
            'Streak: ${formatElapsedDurationShort(currentStreak)} since relapse',
        events: events,
      );
    }

    final Duration startedSince = calculateDurationSinceUtc(
      startedAtUtc: habit.createdAtUtc,
      nowUtc: nowUtc,
    );
    return _HabitTrackingSnapshot(
      isCompletedToday: false,
      streakLabel: 'Started ${formatElapsedDurationShort(startedSince)} ago',
      events: events,
    );
  }

  Future<void> _refreshTrackingForHabit(final Habit habit) async {
    final _HabitTrackingSnapshot snapshot = await _buildTrackingSnapshot(
      habit: habit,
      nowLocal: widget.clock(),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      final Set<String> updatedCompletedTodayHabitIds = <String>{
        ..._completedTodayHabitIds,
      };
      if (snapshot.isCompletedToday) {
        updatedCompletedTodayHabitIds.add(habit.id);
      } else {
        updatedCompletedTodayHabitIds.remove(habit.id);
      }
      _completedTodayHabitIds = updatedCompletedTodayHabitIds;
      _streakLabelsByHabitId = <String, String>{
        ..._streakLabelsByHabitId,
        habit.id: snapshot.streakLabel,
      };
      _eventsByHabitId = <String, List<HabitEvent>>{
        ..._eventsByHabitId,
        habit.id: snapshot.events,
      };
    });
  }

  void _showPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _showNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _jumpToCurrentMonth() {
    setState(() {
      _visibleMonth = toMonthStart(widget.clock());
    });
  }

  Future<void> _openSettings() async {
    final SettingsScreenResult? result = await Navigator.of(context)
        .push<SettingsScreenResult>(
          MaterialPageRoute<SettingsScreenResult>(
            builder: (final BuildContext context) {
              return SettingsScreen(
                habitRepository: widget.habitRepository,
                appSettingsRepository: widget.appSettingsRepository,
                habitReminderRepository: widget.habitReminderRepository,
                notificationScheduler: widget.notificationScheduler,
              );
            },
          ),
        );
    if (!mounted) {
      return;
    }
    await _loadHabits();
    if (!mounted) {
      return;
    }
    if (result == SettingsScreenResult.dataReset) {
      _showSnackBar('All data reset.');
    }
  }

  Future<void> _createHabit() async {
    const _HabitFormInitialReminder initialReminder = _HabitFormInitialReminder(
      isEnabled: false,
      reminderTimeMinutes: _defaultReminderTimeMinutes,
      hasStoredRow: false,
    );
    final _HabitFormResult? result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (final BuildContext context) {
        return _HabitFormDialog(
          existingHabitNames: _habits.map((final Habit h) => h.name),
          initialReminder: initialReminder,
          timeFormat: _appSettings.timeFormat,
          remindersGloballyEnabled: _appSettings.remindersEnabled,
          notificationScheduler: widget.notificationScheduler,
        );
      },
    );

    if (result == null) {
      return;
    }

    final Habit habit = Habit(
      id: _generateHabitId(),
      name: result.name,
      iconKey: result.iconKey,
      colorHex: result.colorHex,
      mode: result.mode,
      note: result.note,
      createdAtUtc: DateTime.now().toUtc(),
    );

    final bool habitSaved = await _saveHabit(
      habit: habit,
      successMessage: 'Habit created.',
    );
    if (!habitSaved) {
      return;
    }
    await _saveHabitReminderFromForm(
      habit: habit,
      result: result,
      keepDisabledReminderRow: false,
    );
  }

  Future<void> _editHabit(final Habit habit) async {
    final HabitReminder? existingReminder = await widget.habitReminderRepository
        .findReminderByHabitId(habit.id);
    if (!mounted) {
      return;
    }
    final _HabitFormInitialReminder initialReminder = _HabitFormInitialReminder(
      isEnabled: existingReminder?.isEnabled ?? false,
      reminderTimeMinutes:
          existingReminder?.reminderTimeMinutes ?? _defaultReminderTimeMinutes,
      hasStoredRow: existingReminder != null,
    );

    final _HabitFormResult? result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (final BuildContext context) {
        return _HabitFormDialog(
          initialHabit: habit,
          existingHabitNames: _habits.map((final Habit h) => h.name),
          initialReminder: initialReminder,
          timeFormat: _appSettings.timeFormat,
          remindersGloballyEnabled: _appSettings.remindersEnabled,
          notificationScheduler: widget.notificationScheduler,
        );
      },
    );

    if (result == null) {
      return;
    }

    final Habit updatedHabit = habit.copyWith(
      name: result.name,
      iconKey: result.iconKey,
      colorHex: result.colorHex,
      mode: result.mode,
      note: result.note,
      clearNote: result.note == null,
    );

    final bool habitSaved = await _saveHabit(
      habit: updatedHabit,
      successMessage: 'Habit updated.',
    );
    if (!habitSaved) {
      return;
    }
    await _saveHabitReminderFromForm(
      habit: updatedHabit,
      result: result,
      keepDisabledReminderRow: initialReminder.hasStoredRow,
    );
  }

  Future<bool> _saveHabit({
    required final Habit habit,
    required final String successMessage,
  }) async {
    try {
      await widget.habitRepository.saveHabit(habit);
      await _loadHabits();
      if (!mounted) {
        return true;
      }
      _showSnackBar(successMessage);
      return true;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to save habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return false;
      }
      _showSnackBar('Could not save habit.');
      return false;
    }
  }

  Future<void> _saveHabitReminderFromForm({
    required final Habit habit,
    required final _HabitFormResult result,
    required final bool keepDisabledReminderRow,
  }) async {
    try {
      final HabitReminder reminder = HabitReminder(
        habitId: habit.id,
        isEnabled: result.reminderEnabled,
        reminderTimeMinutes: result.reminderTimeMinutes,
      );
      if (!result.reminderEnabled && !keepDisabledReminderRow) {
        await widget.habitReminderRepository.deleteReminderByHabitId(habit.id);
      } else {
        await widget.habitReminderRepository.saveReminder(reminder);
      }

      if (result.reminderEnabled && _appSettings.remindersEnabled) {
        await widget.notificationScheduler.scheduleDailyReminder(
          habitId: habit.id,
          habitName: habit.name,
          reminderTimeMinutes: result.reminderTimeMinutes,
        );
      } else {
        await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to update reminder from habit form for habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Habit saved, but reminder settings could not be updated.');
    }
  }

  Future<void> _archiveHabit(final Habit habit) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Text('Archive Habit'),
          content: Text('Archive "${habit.name}"? You can unarchive it later.'),
          actions: <Widget>[
            TextButton(
              key: const Key('archive_cancel_button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('archive_confirm_button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.habitRepository.archiveHabit(
        habitId: habit.id,
        archivedAtUtc: DateTime.now().toUtc(),
      );
      try {
        await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      } on Object catch (error, stackTrace) {
        _logger.error(
          'Failed to cancel reminder after archiving habit ${habit.id}.',
          error: error,
          stackTrace: stackTrace,
        );
      }
      await _loadHabits();
      if (!mounted) {
        return;
      }
      _showSnackBar('Habit archived.');
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to archive habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not archive habit.');
    }
  }

  Future<void> _onQuickActionTap(final Habit habit) async {
    if (_trackingHabitIds.contains(habit.id)) {
      return;
    }

    setState(() {
      _trackingHabitIds = <String>{..._trackingHabitIds, habit.id};
    });

    try {
      if (habit.mode == HabitMode.positive) {
        await _togglePositiveCompletionForToday(habit);
      } else {
        final HabitEvent? latestRelapse = _latestRelapseEventForHabit(habit.id);
        if (latestRelapse != null) {
          await _undoLatestRelapse(habit: habit, latestRelapse: latestRelapse);
        } else {
          await _logRelapseAtLocalDateTime(
            habit: habit,
            localDateTime: widget.clock(),
            feedbackMessage: 'Relapse logged.',
          );
        }
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to track habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not update habit tracking.');
    } finally {
      if (mounted) {
        setState(() {
          final Set<String> updatedBusyIds = <String>{..._trackingHabitIds};
          updatedBusyIds.remove(habit.id);
          _trackingHabitIds = updatedBusyIds;
        });
      }
    }
  }

  Future<void> _togglePositiveCompletionForToday(final Habit habit) async {
    final DateTime nowLocal = widget.clock();
    await _togglePositiveCompletionForDay(
      habit: habit,
      localDayKey: toLocalDayKey(nowLocal),
      eventLocalDateTime: nowLocal,
      addSuccessMessage: 'Marked done for today.',
      removeSuccessMessage: 'Today marked as not done.',
      duplicateMessage: 'Already marked done for today.',
    );
  }

  Future<void> _togglePositiveCompletionForDay({
    required final Habit habit,
    required final String localDayKey,
    required final DateTime eventLocalDateTime,
    required final String addSuccessMessage,
    required final String removeSuccessMessage,
    required final String duplicateMessage,
  }) async {
    final List<HabitEvent> eventsOnDay = await widget.habitEventRepository
        .listEventsForHabitOnDay(habitId: habit.id, localDayKey: localDayKey);
    final List<HabitEvent> completionEvents = eventsOnDay
        .where(
          (final HabitEvent event) =>
              event.eventType == HabitEventType.complete,
        )
        .toList(growable: false);

    if (completionEvents.isNotEmpty) {
      for (final HabitEvent completion in completionEvents) {
        await widget.habitEventRepository.deleteEventById(completion.id);
      }
      await _refreshTrackingForHabit(habit);
      if (!mounted) {
        return;
      }
      _showSnackBar(removeSuccessMessage);
      return;
    }

    final HabitEvent completion = HabitEvent(
      id: _generateHabitEventId(),
      habitId: habit.id,
      eventType: HabitEventType.complete,
      occurredAtUtc: eventLocalDateTime.toUtc(),
      localDayKey: localDayKey,
      tzOffsetMinutesAtEvent: captureTzOffsetMinutesAtEvent(eventLocalDateTime),
    );

    try {
      await widget.habitEventRepository.saveEvent(completion);
    } on DuplicateHabitCompletionException {
      await _refreshTrackingForHabit(habit);
      if (!mounted) {
        return;
      }
      _showSnackBar(duplicateMessage);
      return;
    }

    await _refreshTrackingForHabit(habit);
    if (!mounted) {
      return;
    }
    _showSnackBar(addSuccessMessage);
  }

  Future<void> _toggleNegativeRelapseForDay({
    required final Habit habit,
    required final String localDayKey,
    required final DateTime eventLocalDateTime,
    required final String addSuccessMessage,
    required final String removeSuccessMessage,
  }) async {
    final List<HabitEvent> eventsOnDay = await widget.habitEventRepository
        .listEventsForHabitOnDay(habitId: habit.id, localDayKey: localDayKey);
    final List<HabitEvent> relapseEvents = eventsOnDay
        .where(
          (final HabitEvent event) => event.eventType == HabitEventType.relapse,
        )
        .toList(growable: false);

    if (relapseEvents.isNotEmpty) {
      for (final HabitEvent relapse in relapseEvents) {
        await widget.habitEventRepository.deleteEventById(relapse.id);
      }
      await _refreshTrackingForHabit(habit);
      if (!mounted) {
        return;
      }
      _showSnackBar(removeSuccessMessage);
      return;
    }

    final HabitEvent relapse = HabitEvent(
      id: _generateHabitEventId(),
      habitId: habit.id,
      eventType: HabitEventType.relapse,
      occurredAtUtc: eventLocalDateTime.toUtc(),
      localDayKey: localDayKey,
      tzOffsetMinutesAtEvent: captureTzOffsetMinutesAtEvent(eventLocalDateTime),
    );
    await widget.habitEventRepository.saveEvent(relapse);

    await _refreshTrackingForHabit(habit);
    if (!mounted) {
      return;
    }
    _showSnackBar(addSuccessMessage);
  }

  HabitEvent? _latestRelapseEventForHabit(final String habitId) {
    final List<HabitEvent>? events = _eventsByHabitId[habitId];
    if (events == null || events.isEmpty) {
      return null;
    }

    HabitEvent? latestRelapse;
    for (final HabitEvent event in events) {
      if (event.eventType != HabitEventType.relapse) {
        continue;
      }
      if (latestRelapse == null ||
          event.occurredAtUtc.isAfter(latestRelapse.occurredAtUtc)) {
        latestRelapse = event;
      }
    }
    return latestRelapse;
  }

  Future<void> _undoLatestRelapse({
    required final Habit habit,
    required final HabitEvent latestRelapse,
  }) async {
    await widget.habitEventRepository.deleteEventById(latestRelapse.id);
    await _refreshTrackingForHabit(habit);
    if (!mounted) {
      return;
    }
    _showSnackBar('Latest relapse undone.');
  }

  Future<void> _onGridCellTap({
    required final Habit habit,
    required final HabitMonthCell cell,
  }) async {
    if (_trackingHabitIds.contains(habit.id)) {
      return;
    }

    final DateTime nowLocal = widget.clock();
    final _GridEditGuardResult guardResult = _evaluateGridEditGuard(
      localDayKey: cell.localDayKey,
      nowLocal: nowLocal,
    );
    if (!guardResult.isAllowed) {
      if (mounted) {
        _showSnackBar(guardResult.feedbackMessage!);
      }
      return;
    }

    setState(() {
      _trackingHabitIds = <String>{..._trackingHabitIds, habit.id};
    });

    try {
      final DateTime eventLocalDateTime = _resolveGridEventLocalDateTime(
        localDayKey: cell.localDayKey,
        nowLocal: nowLocal,
      );
      if (habit.mode == HabitMode.positive) {
        await _togglePositiveCompletionForDay(
          habit: habit,
          localDayKey: cell.localDayKey,
          eventLocalDateTime: eventLocalDateTime,
          addSuccessMessage: 'Completion added for ${cell.localDayKey}.',
          removeSuccessMessage: 'Completion removed for ${cell.localDayKey}.',
          duplicateMessage: 'Already marked done for ${cell.localDayKey}.',
        );
      } else {
        await _toggleNegativeRelapseForDay(
          habit: habit,
          localDayKey: cell.localDayKey,
          eventLocalDateTime: eventLocalDateTime,
          addSuccessMessage: 'Relapse logged for ${cell.localDayKey}.',
          removeSuccessMessage: 'Relapse removed for ${cell.localDayKey}.',
        );
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to toggle grid cell ${cell.localDayKey} for habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not update that day.');
    } finally {
      if (mounted) {
        setState(() {
          final Set<String> updatedBusyIds = <String>{..._trackingHabitIds};
          updatedBusyIds.remove(habit.id);
          _trackingHabitIds = updatedBusyIds;
        });
      }
    }
  }

  _GridEditGuardResult _evaluateGridEditGuard({
    required final String localDayKey,
    required final DateTime nowLocal,
  }) {
    final DateTime todayDate = _dateOnly(nowLocal);
    final DateTime targetDate = _parseLocalDayKey(localDayKey);
    if (targetDate.isAfter(todayDate)) {
      return const _GridEditGuardResult.blocked(
        'Future days cannot be edited.',
      );
    }

    return const _GridEditGuardResult.allowed();
  }

  DateTime _resolveGridEventLocalDateTime({
    required final String localDayKey,
    required final DateTime nowLocal,
  }) {
    final DateTime targetDate = _parseLocalDayKey(localDayKey);
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      nowLocal.hour,
      nowLocal.minute,
      nowLocal.second,
      nowLocal.millisecond,
      nowLocal.microsecond,
    );
  }

  DateTime _parseLocalDayKey(final String localDayKey) {
    final List<String> parts = localDayKey.split('-');
    if (parts.length != 3) {
      throw ArgumentError.value(
        localDayKey,
        'localDayKey',
        'localDayKey must use YYYY-MM-DD format.',
      );
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw ArgumentError.value(
        localDayKey,
        'localDayKey',
        'localDayKey must use YYYY-MM-DD format.',
      );
    }
    final DateTime parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw ArgumentError.value(
        localDayKey,
        'localDayKey',
        'localDayKey must represent a valid calendar date.',
      );
    }
    return parsed;
  }

  DateTime _dateOnly(final DateTime dateTime) {
    final DateTime normalized = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateTime(normalized.year, normalized.month, normalized.day);
  }

  Future<void> _promptBackdatedRelapse(final Habit habit) async {
    if (_trackingHabitIds.contains(habit.id)) {
      return;
    }

    final DateTime nowLocal = widget.clock();
    final DateTime? selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (final BuildContext context) {
        return _BackdateRelapseDialog(nowLocal: nowLocal);
      },
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _trackingHabitIds = <String>{..._trackingHabitIds, habit.id};
    });

    try {
      final DateTime localDateTime = resolveBackdatedRelapseLocalDateTime(
        nowLocal: nowLocal,
        selectedLocalDate: selectedDate,
      );
      await _logRelapseAtLocalDateTime(
        habit: habit,
        localDateTime: localDateTime,
        feedbackMessage: 'Backdated relapse logged.',
      );
    } on RelapseBackdateOutOfRangeException {
      if (!mounted) {
        return;
      }
      _showSnackBar('Backdate must be within the last 7 days.');
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to save backdated relapse for habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not log backdated relapse.');
    } finally {
      if (mounted) {
        setState(() {
          final Set<String> updatedBusyIds = <String>{..._trackingHabitIds};
          updatedBusyIds.remove(habit.id);
          _trackingHabitIds = updatedBusyIds;
        });
      }
    }
  }

  Future<void> _logRelapseAtLocalDateTime({
    required final Habit habit,
    required final DateTime localDateTime,
    required final String feedbackMessage,
  }) async {
    final HabitEvent event = HabitEvent(
      id: _generateHabitEventId(),
      habitId: habit.id,
      eventType: HabitEventType.relapse,
      occurredAtUtc: localDateTime.toUtc(),
      localDayKey: toLocalDayKey(localDateTime),
      tzOffsetMinutesAtEvent: captureTzOffsetMinutesAtEvent(localDateTime),
    );
    await widget.habitEventRepository.saveEvent(event);
    await _refreshTrackingForHabit(habit);
    if (!mounted) {
      return;
    }
    _showSnackBar(feedbackMessage);
  }

  String _generateHabitEventId() {
    _eventIdCounter += 1;
    return 'event_${DateTime.now().toUtc().microsecondsSinceEpoch}_$_eventIdCounter';
  }

  void _showSnackBar(final String message) {
    showTransientFeedback(context, message);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: <Widget>[
          IconButton(
            key: const Key('home_open_settings_button'),
            onPressed: _openSettings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_add_habit_fab'),
        onPressed: _createHabit,
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(final BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadHabits);
    }

    if (_habits.isEmpty) {
      return _EmptyState(onCreate: _createHabit);
    }

    final DateTime nowLocal = widget.clock();
    final DateTime currentMonth = toMonthStart(nowLocal);
    final bool isViewingCurrentMonth =
        _visibleMonth.year == currentMonth.year &&
        _visibleMonth.month == currentMonth.month;
    final String todayLocalDayKey = toLocalDayKey(nowLocal);

    return Column(
      children: <Widget>[
        _MonthNavigationBar(
          visibleMonth: _visibleMonth,
          isViewingCurrentMonth: isViewingCurrentMonth,
          onPreviousMonth: _showPreviousMonth,
          onNextMonth: _showNextMonth,
          onJumpToCurrentMonth: _jumpToCurrentMonth,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl * 3,
            ),
            itemCount: _habits.length,
            separatorBuilder: (final BuildContext context, final int index) {
              return const SizedBox(height: AppSpacing.md);
            },
            itemBuilder: (final BuildContext context, final int index) {
              final Habit habit = _habits[index];
              return _HabitCard(
                key: ValueKey<String>('habit_card_${habit.id}'),
                habit: habit,
                streakSummary:
                    _streakLabelsByHabitId[habit.id] ??
                    _fallbackStreakSummary(habit),
                isCompletedToday: _completedTodayHabitIds.contains(habit.id),
                hasRelapseHistory:
                    _latestRelapseEventForHabit(habit.id) != null,
                isTrackingActionInProgress: _trackingHabitIds.contains(
                  habit.id,
                ),
                monthlyCells: buildHabitMonthCells(
                  mode: habit.mode,
                  events: _eventsByHabitId[habit.id] ?? const <HabitEvent>[],
                  monthLocal: _visibleMonth,
                  referenceTodayLocalDayKey: todayLocalDayKey,
                  weekStart: _appSettings.weekStart,
                ),
                onQuickAction: () => _onQuickActionTap(habit),
                onShowDetails: () {
                  _showHabitDetails(habit);
                },
                onGridCellTap: (final HabitMonthCell cell) =>
                    _onGridCellTap(habit: habit, cell: cell),
                onEdit: () => _editHabit(habit),
                onBackdateRelapse: () => _promptBackdatedRelapse(habit),
                onArchive: () => _archiveHabit(habit),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showHabitDetails(final Habit habit) async {
    final DateTime nowLocal = widget.clock();
    final List<HabitEvent> events =
        _eventsByHabitId[habit.id] ?? const <HabitEvent>[];
    final _HabitDetailsSnapshot details = _buildHabitDetailsSnapshot(
      habit: habit,
      events: events,
      nowLocal: nowLocal,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (final BuildContext context) {
        return _HabitDetailsSheet(details: details);
      },
    );
  }

  _HabitDetailsSnapshot _buildHabitDetailsSnapshot({
    required final Habit habit,
    required final List<HabitEvent> events,
    required final DateTime nowLocal,
  }) {
    if (habit.mode == HabitMode.positive) {
      final String referenceLocalDayKey = toLocalDayKey(nowLocal);
      final int currentStreak = calculatePositiveCurrentStreak(
        events: events,
        referenceLocalDayKey: referenceLocalDayKey,
      );
      final int bestStreak = calculatePositiveBestStreak(events: events);
      final int totalCompletions = events
          .where(
            (final HabitEvent event) =>
                event.eventType == HabitEventType.complete,
          )
          .map((final HabitEvent event) => event.localDayKey)
          .toSet()
          .length;
      return _HabitDetailsSnapshot(
        habitId: habit.id,
        habitName: habit.name,
        iconKey: habit.iconKey,
        modeSummary: 'Positive habit details',
        metrics: <_HabitDetailMetric>[
          _HabitDetailMetric(
            id: 'current_streak',
            label: 'Current completion streak',
            value: _formatDayCount(currentStreak),
            semanticsLabel:
                'Current completion streak: ${_formatDayCount(currentStreak)}',
          ),
          _HabitDetailMetric(
            id: 'best_streak',
            label: 'Best completion streak',
            value: _formatDayCount(bestStreak),
            semanticsLabel:
                'Best completion streak: ${_formatDayCount(bestStreak)}',
          ),
          _HabitDetailMetric(
            id: 'total_events',
            label: 'Total completion days',
            value: _formatDayCount(totalCompletions),
            semanticsLabel:
                'Total completion days: ${_formatDayCount(totalCompletions)}',
          ),
        ],
      );
    }

    final DateTime nowUtc = nowLocal.toUtc();
    final Duration currentStreak =
        calculateNegativeCurrentStreak(events: events, nowUtc: nowUtc) ??
        calculateDurationSinceUtc(
          startedAtUtc: habit.createdAtUtc,
          nowUtc: nowUtc,
        );
    final Duration bestStreak = _calculateNegativeBestStreak(
      habit: habit,
      events: events,
      nowUtc: nowUtc,
    );
    final int totalRelapses = events
        .where(
          (final HabitEvent event) => event.eventType == HabitEventType.relapse,
        )
        .length;
    final String currentStreakLabel = formatElapsedDurationShort(currentStreak);
    final String bestStreakLabel = formatElapsedDurationShort(bestStreak);
    return _HabitDetailsSnapshot(
      habitId: habit.id,
      habitName: habit.name,
      iconKey: habit.iconKey,
      modeSummary: 'Negative habit details',
      metrics: <_HabitDetailMetric>[
        _HabitDetailMetric(
          id: 'current_streak',
          label: 'Current relapse-free streak',
          value: currentStreakLabel,
          semanticsLabel: 'Current relapse-free streak: $currentStreakLabel',
        ),
        _HabitDetailMetric(
          id: 'best_streak',
          label: 'Best relapse-free streak',
          value: bestStreakLabel,
          semanticsLabel: 'Best relapse-free streak: $bestStreakLabel',
        ),
        _HabitDetailMetric(
          id: 'total_events',
          label: 'Total relapses',
          value: _formatCount(
            totalRelapses,
            singularNoun: 'relapse',
            pluralNoun: 'relapses',
          ),
          semanticsLabel:
              'Total relapses: ${_formatCount(totalRelapses, singularNoun: 'relapse', pluralNoun: 'relapses')}',
        ),
      ],
    );
  }

  Duration _calculateNegativeBestStreak({
    required final Habit habit,
    required final List<HabitEvent> events,
    required final DateTime nowUtc,
  }) {
    final List<DateTime> sortedRelapseInstants =
        events
            .where(
              (final HabitEvent event) =>
                  event.eventType == HabitEventType.relapse,
            )
            .map((final HabitEvent event) => event.occurredAtUtc)
            .toList(growable: false)
          ..sort((final DateTime a, final DateTime b) => a.compareTo(b));
    if (sortedRelapseInstants.isEmpty) {
      return calculateDurationSinceUtc(
        startedAtUtc: habit.createdAtUtc,
        nowUtc: nowUtc,
      );
    }
    DateTime boundary = habit.createdAtUtc;
    Duration best = Duration.zero;
    for (final DateTime relapseUtc in sortedRelapseInstants) {
      final Duration candidate = calculateDurationSinceUtc(
        startedAtUtc: boundary,
        nowUtc: relapseUtc,
      );
      if (candidate > best) {
        best = candidate;
      }
      if (relapseUtc.isAfter(boundary)) {
        boundary = relapseUtc;
      }
    }
    final Duration sinceBoundary = calculateDurationSinceUtc(
      startedAtUtc: boundary,
      nowUtc: nowUtc,
    );
    if (sinceBoundary > best) {
      best = sinceBoundary;
    }
    return best;
  }

  String _fallbackStreakSummary(final Habit habit) {
    return habit.mode == HabitMode.positive
        ? 'Streak: 0 days'
        : 'Started 0m ago';
  }
}

class _TrackingLoadResult {
  const _TrackingLoadResult({
    required this.completedTodayHabitIds,
    required this.streakLabelsByHabitId,
    required this.eventsByHabitId,
  });

  final Set<String> completedTodayHabitIds;
  final Map<String, String> streakLabelsByHabitId;
  final Map<String, List<HabitEvent>> eventsByHabitId;
}

class _HabitTrackingSnapshot {
  const _HabitTrackingSnapshot({
    required this.isCompletedToday,
    required this.streakLabel,
    required this.events,
  });

  final bool isCompletedToday;
  final String streakLabel;
  final List<HabitEvent> events;
}

class _GridEditGuardResult {
  const _GridEditGuardResult.allowed()
    : isAllowed = true,
      feedbackMessage = null;

  const _GridEditGuardResult.blocked(this.feedbackMessage) : isAllowed = false;

  final bool isAllowed;
  final String? feedbackMessage;
}

class _HabitDetailsSnapshot {
  const _HabitDetailsSnapshot({
    required this.habitId,
    required this.habitName,
    required this.iconKey,
    required this.modeSummary,
    required this.metrics,
  });

  final String habitId;
  final String habitName;
  final String iconKey;
  final String modeSummary;
  final List<_HabitDetailMetric> metrics;
}

class _HabitDetailMetric {
  const _HabitDetailMetric({
    required this.id,
    required this.label,
    required this.value,
    required this.semanticsLabel,
  });

  final String id;
  final String label;
  final String value;
  final String semanticsLabel;
}

class _MonthNavigationBar extends StatelessWidget {
  const _MonthNavigationBar({
    required this.visibleMonth,
    required this.isViewingCurrentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onJumpToCurrentMonth,
  });

  final DateTime visibleMonth;
  final bool isViewingCurrentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onJumpToCurrentMonth;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            key: const Key('home_month_prev_button'),
            onPressed: onPreviousMonth,
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              formatMonthLabel(visibleMonth),
              key: const Key('home_month_label'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const Key('home_month_next_button'),
            onPressed: onNextMonth,
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: isViewingCurrentMonth
                    ? const Chip(
                        key: Key('home_month_current_chip'),
                        label: Text('Current'),
                      )
                    : TextButton(
                        key: const Key('home_month_jump_current_button'),
                        onPressed: onJumpToCurrentMonth,
                        child: const Text('Go to current'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final Future<void> Function() onCreate;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.track_changes_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create your first habit to start tracking progress.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('home_create_first_habit_button'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Habit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            color: Theme.of(context).colorScheme.errorContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    super.key,
    required this.habit,
    required this.streakSummary,
    required this.isCompletedToday,
    required this.hasRelapseHistory,
    required this.isTrackingActionInProgress,
    required this.monthlyCells,
    required this.onQuickAction,
    required this.onShowDetails,
    required this.onGridCellTap,
    required this.onEdit,
    required this.onBackdateRelapse,
    required this.onArchive,
  });

  final Habit habit;
  final String streakSummary;
  final bool isCompletedToday;
  final bool hasRelapseHistory;
  final bool isTrackingActionInProgress;
  final List<HabitMonthCell> monthlyCells;
  final Future<void> Function() onQuickAction;
  final VoidCallback onShowDetails;
  final Future<void> Function(HabitMonthCell cell) onGridCellTap;
  final Future<void> Function() onEdit;
  final Future<void> Function() onBackdateRelapse;
  final Future<void> Function() onArchive;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color accentColor = _colorFromHex(habit.colorHex);
    final Color cardColor = colorScheme.surfaceContainerHighest;
    final Color textColor = colorScheme.onSurface;
    final Color supportingTextColor = colorScheme.onSurfaceVariant;
    final Color avatarBackgroundColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.26),
      cardColor,
    );
    final Color statusColor = switch (habit.mode) {
      HabitMode.positive => isCompletedToday ? textColor : supportingTextColor,
      HabitMode.negative => hasRelapseHistory ? textColor : supportingTextColor,
    };

    final String modeLabel = habit.mode == HabitMode.positive
        ? 'Positive habit'
        : 'Negative habit';
    final String detailsHint = habit.mode == HabitMode.positive
        ? 'Long press to view completion streak details and totals.'
        : 'Long press to view relapse-free streak details and totals.';
    final String currentSummary = streakSummary;
    final String doneToday = isCompletedToday ? 'Done today' : 'Not done today';

    final IconData quickActionIcon = switch (habit.mode) {
      HabitMode.positive =>
        isCompletedToday ? Icons.undo_rounded : Icons.check_circle_rounded,
      HabitMode.negative =>
        hasRelapseHistory ? Icons.undo_rounded : Icons.warning_amber_rounded,
    };
    final String quickActionTooltip = switch (habit.mode) {
      HabitMode.positive => isCompletedToday ? 'Undo today' : 'Mark done today',
      HabitMode.negative =>
        hasRelapseHistory ? 'Undo latest relapse' : 'Log relapse now',
    };

    return Card(
      color: cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            key: ValueKey<String>('habit_card_accent_strip_${habit.id}'),
            height: 4,
            color: accentColor.withValues(alpha: 0.9),
          ),
          Semantics(
            key: ValueKey<String>('habit_card_details_target_${habit.id}'),
            label: 'Long press for details on ${habit.name}',
            hint: detailsHint,
            button: true,
            child: ListTile(
              onLongPress: onShowDetails,
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              leading: CircleAvatar(
                key: ValueKey<String>('habit_card_avatar_${habit.id}'),
                backgroundColor: avatarBackgroundColor,
                child: Icon(_iconForKey(habit.iconKey), color: textColor),
              ),
              title: Text(
                habit.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    modeLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: supportingTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentSummary,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (habit.mode == HabitMode.positive)
                    Text(
                      doneToday,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: statusColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (habit.mode == HabitMode.negative)
                    Text(
                      hasRelapseHistory
                          ? 'Relapse logged'
                          : 'No relapse logged',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: statusColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (habit.note != null && habit.note!.isNotEmpty)
                    Text(
                      habit.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: supportingTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: ValueKey<String>(
                      'habit_card_quick_action_${habit.id}',
                    ),
                    onPressed: isTrackingActionInProgress
                        ? null
                        : onQuickAction,
                    icon: isTrackingActionInProgress
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                textColor,
                              ),
                            ),
                          )
                        : Icon(quickActionIcon),
                    tooltip: quickActionTooltip,
                    color: textColor,
                  ),
                  PopupMenuButton<_HabitCardMenuAction>(
                    key: ValueKey<String>('habit_card_menu_${habit.id}'),
                    iconColor: textColor,
                    onSelected: (final _HabitCardMenuAction value) {
                      switch (value) {
                        case _HabitCardMenuAction.edit:
                          onEdit();
                        case _HabitCardMenuAction.backdateRelapse:
                          onBackdateRelapse();
                        case _HabitCardMenuAction.archive:
                          onArchive();
                      }
                    },
                    itemBuilder: (final BuildContext context) {
                      return <PopupMenuEntry<_HabitCardMenuAction>>[
                        PopupMenuItem<_HabitCardMenuAction>(
                          key: ValueKey<String>('habit_card_edit_${habit.id}'),
                          value: _HabitCardMenuAction.edit,
                          child: const Text('Edit Habit'),
                        ),
                        if (habit.mode == HabitMode.negative)
                          PopupMenuItem<_HabitCardMenuAction>(
                            key: ValueKey<String>(
                              'habit_card_backdate_relapse_${habit.id}',
                            ),
                            value: _HabitCardMenuAction.backdateRelapse,
                            child: const Text('Backdate Relapse'),
                          ),
                        PopupMenuItem<_HabitCardMenuAction>(
                          key: ValueKey<String>(
                            'habit_card_archive_${habit.id}',
                          ),
                          value: _HabitCardMenuAction.archive,
                          child: const Text('Archive Habit'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _HabitMonthGrid(
              habitId: habit.id,
              cells: monthlyCells,
              accentColor: accentColor,
              onCellTap: isTrackingActionInProgress ? null : onGridCellTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDetailsSheet extends StatelessWidget {
  const _HabitDetailsSheet({required this.details});

  final _HabitDetailsSnapshot details;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: ValueKey<String>('habit_details_sheet_${details.habitId}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(_iconForKey(details.iconKey)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  details.habitName,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            details.modeSummary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (
            int index = 0;
            index < details.metrics.length;
            index += 1
          ) ...<Widget>[
            _HabitDetailMetricRow(metric: details.metrics[index]),
            if (index < details.metrics.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('habit_details_close_button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDetailMetricRow extends StatelessWidget {
  const _HabitDetailMetricRow({required this.metric});

  final _HabitDetailMetric metric;

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      label: metric.semanticsLabel,
      readOnly: true,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              metric.label,
              key: ValueKey<String>('habit_details_metric_${metric.id}'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            metric.value,
            key: ValueKey<String>('habit_details_value_${metric.id}'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HabitMonthGrid extends StatelessWidget {
  const _HabitMonthGrid({
    required this.habitId,
    required this.cells,
    required this.accentColor,
    required this.onCellTap,
  });

  final String habitId;
  final List<HabitMonthCell> cells;
  final Color accentColor;
  final Future<void> Function(HabitMonthCell cell)? onCellTap;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        const double spacing = AppSpacing.xxs;
        final double availableWidth = constraints.maxWidth - (spacing * 6);
        final double unclampedCellSize = availableWidth / 7;
        final double cellSize = unclampedCellSize.clamp(14.0, 26.0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: AppSpacing.xs),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cells
                  .map((final HabitMonthCell cell) {
                    return _HabitMonthCell(
                      habitId: habitId,
                      cell: cell,
                      accentColor: accentColor,
                      cellSize: cellSize,
                      onTap: onCellTap == null
                          ? null
                          : () {
                              onCellTap!(cell);
                            },
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        );
      },
    );
  }
}

class _HabitMonthCell extends StatelessWidget {
  const _HabitMonthCell({
    required this.habitId,
    required this.cell,
    required this.accentColor,
    required this.cellSize,
    required this.onTap,
  });

  final String habitId;
  final HabitMonthCell cell;
  final Color accentColor;
  final double cellSize;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final _MonthCellVisual visual = _visualForCell(
      context: context,
      cell: cell,
      accentColor: accentColor,
    );
    final bool showDayNumber = cell.isInMonth && cellSize >= 19;
    return Tooltip(
      message: '${cell.localDayKey}: ${visual.tooltipLabel}',
      child: GestureDetector(
        key: ValueKey<String>(
          'habit_grid_cell_tap_${habitId}_${cell.localDayKey}',
        ),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: ValueKey<String>(
            'habit_grid_cell_${habitId}_${cell.localDayKey}_${cell.state.name}',
          ),
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: visual.backgroundColor.withValues(
              alpha: cell.isInMonth ? visual.alpha : visual.alpha * 0.45,
            ),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: visual.borderColor.withValues(
                alpha: cell.isInMonth ? 1 : 0.45,
              ),
              width: visual.borderWidth,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (showDayNumber)
                Text(
                  '${cell.dateLocal.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: cellSize < 22 ? 9 : 10,
                    color: visual.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (visual.showRelapseDot)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: visual.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

_MonthCellVisual _visualForCell({
  required final BuildContext context,
  required final HabitMonthCell cell,
  required final Color accentColor,
}) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final HabitSemanticColors semanticColors = context.semanticColors;
  final Color doneAccentFill = Color.alphaBlend(
    accentColor.withValues(alpha: 0.88),
    colorScheme.surfaceContainerHighest,
  );
  final Color relapseAccentFill = Color.alphaBlend(
    semanticColors.negative.withValues(alpha: 0.28),
    colorScheme.surfaceContainerHighest,
  );
  final Color positiveClearFill = Color.alphaBlend(
    semanticColors.positive.withValues(alpha: 0.24),
    colorScheme.surfaceContainerHighest,
  );
  final Color futureFill = colorScheme.surfaceContainerHighest;
  return switch (cell.state) {
    HabitMonthCellState.positiveDone => _MonthCellVisual(
      backgroundColor: doneAccentFill,
      borderColor: accentColor.withValues(alpha: 0.95),
      textColor: _foregroundFor(doneAccentFill),
      alpha: 1,
      borderWidth: 1.2,
      tooltipLabel: 'Done',
    ),
    HabitMonthCellState.positiveMissed => _MonthCellVisual(
      backgroundColor: Color.alphaBlend(
        semanticColors.negative.withValues(alpha: 0.24),
        colorScheme.surfaceContainerHighest,
      ),
      borderColor: semanticColors.negative.withValues(alpha: 0.9),
      textColor: colorScheme.onSurface,
      alpha: 0.95,
      borderWidth: 1,
      tooltipLabel: 'Missed',
    ),
    HabitMonthCellState.positiveFuture => _MonthCellVisual(
      backgroundColor: futureFill,
      borderColor: colorScheme.outlineVariant,
      textColor: colorScheme.onSurfaceVariant,
      alpha: 0.26,
      borderWidth: 1,
      tooltipLabel: 'Future',
    ),
    HabitMonthCellState.negativeRelapse => _MonthCellVisual(
      backgroundColor: relapseAccentFill,
      borderColor: accentColor.withValues(alpha: 0.95),
      textColor: colorScheme.onSurface,
      alpha: 1,
      borderWidth: 1.2,
      tooltipLabel: 'Relapse',
      showRelapseDot: true,
      dotColor: accentColor,
    ),
    HabitMonthCellState.negativeClear => _MonthCellVisual(
      backgroundColor: positiveClearFill,
      borderColor: semanticColors.positive.withValues(alpha: 0.78),
      textColor: colorScheme.onSurface,
      alpha: 0.95,
      borderWidth: 1,
      tooltipLabel: 'No relapse',
    ),
    HabitMonthCellState.negativeFuture => _MonthCellVisual(
      backgroundColor: futureFill,
      borderColor: colorScheme.outlineVariant,
      textColor: colorScheme.onSurfaceVariant,
      alpha: 0.26,
      borderWidth: 1,
      tooltipLabel: 'Future',
    ),
  };
}

class _MonthCellVisual {
  const _MonthCellVisual({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.alpha,
    required this.borderWidth,
    required this.tooltipLabel,
    this.showRelapseDot = false,
    this.dotColor = Colors.transparent,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double alpha;
  final double borderWidth;
  final String tooltipLabel;
  final bool showRelapseDot;
  final Color dotColor;
}

enum _HabitCardMenuAction { edit, backdateRelapse, archive }

class _BackdateRelapseDialog extends StatefulWidget {
  const _BackdateRelapseDialog({required this.nowLocal});

  final DateTime nowLocal;

  @override
  State<_BackdateRelapseDialog> createState() => _BackdateRelapseDialogState();
}

class _BackdateRelapseDialogState extends State<_BackdateRelapseDialog> {
  late final List<DateTime> _candidateDates;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final DateTime now = widget.nowLocal.isUtc
        ? widget.nowLocal.toLocal()
        : widget.nowLocal;
    final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);
    _candidateDates = List<DateTime>.generate(
      7,
      (final int index) => todayDateOnly.subtract(Duration(days: index + 1)),
      growable: false,
    );
    _selectedDate = _candidateDates.first;
  }

  @override
  Widget build(final BuildContext context) {
    return AlertDialog(
      title: const Text('Backdate Relapse'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Select a day from the last 7 days.'),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<DateTime>(
            key: const Key('backdate_relapse_date_dropdown'),
            initialValue: _selectedDate,
            items: _candidateDates
                .map((final DateTime date) {
                  return DropdownMenuItem<DateTime>(
                    value: date,
                    child: Text(_formatBackdateDateLabel(date)),
                  );
                })
                .toList(growable: false),
            onChanged: (final DateTime? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedDate = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('backdate_relapse_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('backdate_relapse_confirm_button'),
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: const Text('Log Relapse'),
        ),
      ],
    );
  }
}

class _HabitFormDialog extends StatefulWidget {
  const _HabitFormDialog({
    required this.existingHabitNames,
    required this.initialReminder,
    required this.timeFormat,
    required this.remindersGloballyEnabled,
    required this.notificationScheduler,
    this.initialHabit,
  });

  final Habit? initialHabit;
  final Iterable<String> existingHabitNames;
  final _HabitFormInitialReminder initialReminder;
  final AppTimeFormat timeFormat;
  final bool remindersGloballyEnabled;
  final ReminderNotificationScheduler notificationScheduler;

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  late String _selectedIconKey;
  late String _selectedColorHex;
  late HabitMode _selectedMode;
  late bool _isReminderEnabled;
  late int _reminderTimeMinutes;
  int _iconPickerPage = 0;
  bool _didInitializeIconPickerPage = false;
  bool _isUpdatingReminderPermission = false;

  bool get _isEditing => widget.initialHabit != null;
  bool get _isCustomColorSelected =>
      !_habitColorHexOptions.contains(_selectedColorHex);

  @override
  void initState() {
    super.initState();

    final Habit? initialHabit = widget.initialHabit;
    _nameController = TextEditingController(text: initialHabit?.name ?? '');
    _noteController = TextEditingController(text: initialHabit?.note ?? '');

    final String initialColorHex = _normalizeStoredColorHex(
      initialHabit?.colorHex,
      fallback: _habitColorHexOptions.first,
    );

    _selectedIconKey = _habitIconByKey.containsKey(initialHabit?.iconKey)
        ? initialHabit!.iconKey
        : _habitIconOptions.first.key;
    _selectedColorHex = initialColorHex;
    _selectedMode = initialHabit?.mode ?? HabitMode.positive;
    _isReminderEnabled = widget.initialReminder.isEnabled;
    _reminderTimeMinutes = widget.initialReminder.reminderTimeMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Color previewColor = _colorFromHex(_selectedColorHex);
    final Color previewTextColor = _foregroundFor(previewColor);
    final String previewName = _nameController.text.trim().isEmpty
        ? 'Habit preview'
        : _nameController.text.trim();

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Habit' : 'Create Habit'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  key: const Key('habit_form_name_field'),
                  controller: _nameController,
                  autofocus: !_isEditing,
                  maxLength: DomainConstraints.habitNameMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (final String value) => setState(() {}),
                  validator: _validateName,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Icon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                _buildIconPicker(context),
                const SizedBox(height: AppSpacing.md),
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _habitColorHexOptions
                      .map((final String hex) {
                        final Color color = _colorFromHex(hex);
                        final Color onColor = _foregroundFor(color);
                        final bool isSelected = _selectedColorHex == hex;
                        final BorderSide border = BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        );
                        return ChoiceChip(
                          key: ValueKey<String>(
                            'habit_form_color_${hex.replaceAll('#', '')}',
                          ),
                          label: Text(
                            'Aa',
                            style: TextStyle(
                              color: onColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: isSelected,
                          side: border,
                          backgroundColor: color,
                          selectedColor: color,
                          onSelected: (final bool selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _selectedColorHex = hex;
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const Key('habit_form_custom_color_button'),
                      onPressed: _promptForCustomColor,
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Custom'),
                    ),
                    if (_isCustomColorSelected)
                      Chip(
                        key: const Key('habit_form_color_custom_selected'),
                        avatar: CircleAvatar(
                          backgroundColor: _colorFromHex(_selectedColorHex),
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              color: _foregroundFor(
                                _colorFromHex(_selectedColorHex),
                              ),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        label: Text(_selectedColorHex),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Mode', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: HabitMode.values
                      .map((final HabitMode mode) {
                        final bool isSelected = _selectedMode == mode;
                        final String label = mode == HabitMode.positive
                            ? 'Positive'
                            : 'Negative';
                        final IconData icon = mode == HabitMode.positive
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded;
                        return ChoiceChip(
                          key: ValueKey<String>('habit_form_mode_${mode.name}'),
                          avatar: Icon(icon, size: 18),
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (final bool selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _selectedMode = mode;
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Reminder', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                if (!widget.remindersGloballyEnabled) ...<Widget>[
                  Text(
                    'Global reminders are off. Per-habit settings will be saved and applied when global reminders are enabled again.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                SwitchListTile(
                  key: const Key('habit_form_reminder_toggle'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily reminder'),
                  subtitle: Text(
                    _isReminderEnabled
                        ? 'Daily at ${_formatReminderTime(_reminderTimeMinutes)}'
                        : 'Reminder off',
                  ),
                  value: _isReminderEnabled,
                  onChanged: _isUpdatingReminderPermission
                      ? null
                      : _toggleReminder,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('habit_form_reminder_time_button'),
                    onPressed:
                        _isUpdatingReminderPermission || !_isReminderEnabled
                        ? null
                        : _pickReminderTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Change time'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('habit_form_note_field'),
                  controller: _noteController,
                  maxLength: DomainConstraints.habitNoteMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateNote,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Preview', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                DecoratedBox(
                  key: const Key('habit_form_preview_card'),
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              _iconForKey(_selectedIconKey),
                              color: previewTextColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                previewName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: previewTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _selectedMode == HabitMode.positive
                              ? 'Positive'
                              : 'Negative',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: previewTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('habit_form_submit_button'),
          onPressed: _submit,
          child: Text(_isEditing ? 'Save Changes' : 'Create Habit'),
        ),
      ],
    );
  }

  String? _validateName(final String? value) {
    final String candidateName = value ?? '';

    final HabitNameValidationError? error = HabitValidation.validateName(
      candidateName,
    );
    if (error == HabitNameValidationError.empty) {
      return 'Name is required.';
    }
    if (error == HabitNameValidationError.tooLong) {
      return 'Name must be 1-${DomainConstraints.habitNameMaxLength} characters.';
    }

    final bool isDuplicate = HabitValidation.hasCaseInsensitiveDuplicateName(
      candidateName: candidateName,
      existingNames: widget.existingHabitNames,
      currentName: widget.initialHabit?.name,
    );
    if (isDuplicate) {
      return 'Name already exists.';
    }

    return null;
  }

  String? _validateNote(final String? value) {
    final HabitNoteValidationError? error = HabitValidation.validateNote(value);
    if (error == HabitNoteValidationError.tooLong) {
      return 'Note must be ${DomainConstraints.habitNoteMaxLength} characters or less.';
    }
    return null;
  }

  Future<void> _submit() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String normalizedColorHex =
        _canonicalHexColorOrNull(_selectedColorHex) ??
        _selectedColorHex.trim().toUpperCase();

    final String noteText = _noteController.text.trim();
    Navigator.of(context).pop(
      _HabitFormResult(
        name: _nameController.text.trim(),
        iconKey: _selectedIconKey,
        colorHex: normalizedColorHex,
        mode: _selectedMode,
        note: noteText.isEmpty ? null : noteText,
        reminderEnabled: _isReminderEnabled,
        reminderTimeMinutes: _reminderTimeMinutes,
      ),
    );
  }

  Future<void> _toggleReminder(final bool enabled) async {
    if (!enabled) {
      setState(() {
        _isReminderEnabled = false;
      });
      return;
    }
    if (!widget.remindersGloballyEnabled) {
      setState(() {
        _isReminderEnabled = true;
      });
      return;
    }

    setState(() {
      _isUpdatingReminderPermission = true;
    });
    final bool permissionGranted = await _ensurePermissionForReminders();
    if (!mounted) {
      return;
    }
    setState(() {
      _isUpdatingReminderPermission = false;
      if (permissionGranted) {
        _isReminderEnabled = true;
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderTimeMinutes ~/ 60,
        minute: _reminderTimeMinutes % 60,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _reminderTimeMinutes = picked.hour * 60 + picked.minute;
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
          key: const Key('habit_form_permission_fallback_dialog'),
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

    if (widget.timeFormat == AppTimeFormat.twentyFourHour) {
      return '${hour.toString().padLeft(2, '0')}:$minuteText';
    }

    final bool isPm = hour >= 12;
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = isPm ? 'PM' : 'AM';
    return '$hour12:$minuteText $period';
  }

  Future<void> _promptForCustomColor() async {
    HSVColor colorDraft = HSVColor.fromColor(_colorFromHex(_selectedColorHex));
    final String? selectedColorHex = await showDialog<String>(
      context: context,
      builder: (final BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                final BuildContext context,
                final void Function(void Function()) setDialogState,
              ) {
                final Color previewColor = colorDraft.toColor();
                final Color previewTextColor = _foregroundFor(previewColor);
                final String previewHex = _hexFromColor(previewColor);
                return AlertDialog(
                  title: const Text('Custom color'),
                  content: SizedBox(
                    width: 360,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Use sliders to pick a color.'),
                          const SizedBox(height: AppSpacing.sm),
                          DecoratedBox(
                            key: const Key('habit_form_custom_color_preview'),
                            decoration: BoxDecoration(
                              color: previewColor,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 72,
                              child: Center(
                                child: Text(
                                  previewHex,
                                  key: const Key(
                                    'habit_form_custom_color_preview_hex',
                                  ),
                                  style: TextStyle(
                                    color: previewTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Hue ${colorDraft.hue.round()}'),
                          Slider(
                            key: const Key(
                              'habit_form_custom_color_hue_slider',
                            ),
                            min: 0,
                            max: 360,
                            divisions: 360,
                            value: colorDraft.hue,
                            onChanged: (final double value) {
                              setDialogState(() {
                                colorDraft = colorDraft.withHue(value);
                              });
                            },
                          ),
                          Text(
                            'Saturation ${(colorDraft.saturation * 100).round()}%',
                          ),
                          Slider(
                            key: const Key(
                              'habit_form_custom_color_saturation_slider',
                            ),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            value: colorDraft.saturation * 100,
                            onChanged: (final double value) {
                              setDialogState(() {
                                colorDraft = colorDraft.withSaturation(
                                  value / 100,
                                );
                              });
                            },
                          ),
                          Text(
                            'Brightness ${(colorDraft.value * 100).round()}%',
                          ),
                          Slider(
                            key: const Key(
                              'habit_form_custom_color_brightness_slider',
                            ),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            value: colorDraft.value * 100,
                            onChanged: (final double value) {
                              setDialogState(() {
                                colorDraft = colorDraft.withValue(value / 100);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      key: const Key('habit_form_custom_color_apply_button'),
                      onPressed: () {
                        Navigator.of(context).pop(previewHex);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                );
              },
        );
      },
    );
    if (selectedColorHex == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedColorHex = selectedColorHex;
    });
  }

  Widget _buildIconPicker(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme colorScheme = theme.colorScheme;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double minTileWidth = textScale >= 1.4 ? 60 : 52;
        final int columnCount = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(4, 7);
        final int rowCount = textScale >= 1.4 ? 2 : 3;
        final int iconsPerPage = columnCount * rowCount;
        final int pageCount = (_habitIconOptions.length / iconsPerPage).ceil();
        final int selectedIndex = _habitIconOptions.indexWhere(
          (final _HabitIconOption option) => option.key == _selectedIconKey,
        );
        if (!_didInitializeIconPickerPage && selectedIndex >= 0) {
          _iconPickerPage = selectedIndex ~/ iconsPerPage;
          _didInitializeIconPickerPage = true;
        }
        _iconPickerPage = _iconPickerPage.clamp(0, pageCount - 1);

        final int start = _iconPickerPage * iconsPerPage;
        final int end = (start + iconsPerPage).clamp(
          0,
          _habitIconOptions.length,
        );
        final List<_HabitIconOption> visibleOptions = _habitIconOptions.sublist(
          start,
          end,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Page ${_iconPickerPage + 1} of $pageCount',
                    key: const Key('habit_form_icon_page_label'),
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const Key('habit_form_icon_page_previous'),
                  tooltip: 'Previous icon page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _iconPickerPage == 0
                      ? null
                      : () {
                          setState(() {
                            _iconPickerPage -= 1;
                          });
                        },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  key: const Key('habit_form_icon_page_next'),
                  tooltip: 'Next icon page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _iconPickerPage >= pageCount - 1
                      ? null
                      : () {
                          setState(() {
                            _iconPickerPage += 1;
                          });
                        },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            GridView.builder(
              key: ValueKey<String>(
                'habit_form_icon_page_${_iconPickerPage + 1}',
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 1,
              ),
              itemCount: visibleOptions.length,
              itemBuilder: (final BuildContext context, final int index) {
                final _HabitIconOption option = visibleOptions[index];
                final bool isSelected = _selectedIconKey == option.key;
                final BorderSide borderSide = BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                );
                return Semantics(
                  label: '${option.label} icon',
                  selected: isSelected,
                  button: true,
                  child: Tooltip(
                    message: option.label,
                    child: OutlinedButton(
                      key: ValueKey<String>('habit_form_icon_${option.key}'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        side: borderSide,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        backgroundColor: isSelected
                            ? colorScheme.primaryContainer
                            : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedIconKey = option.key;
                        });
                      },
                      child: Icon(
                        option.icon,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        size: textScale >= 1.4 ? 22 : 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _HabitFormResult {
  const _HabitFormResult({
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.mode,
    required this.note,
    required this.reminderEnabled,
    required this.reminderTimeMinutes,
  });

  final String name;
  final String iconKey;
  final String colorHex;
  final HabitMode mode;
  final String? note;
  final bool reminderEnabled;
  final int reminderTimeMinutes;
}

class _HabitFormInitialReminder {
  const _HabitFormInitialReminder({
    required this.isEnabled,
    required this.reminderTimeMinutes,
    required this.hasStoredRow,
  });

  final bool isEnabled;
  final int reminderTimeMinutes;
  final bool hasStoredRow;
}

class _HabitIconOption {
  const _HabitIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const List<_HabitIconOption> _habitIconOptions = <_HabitIconOption>[
  _HabitIconOption(key: 'book', label: 'Read', icon: Icons.menu_book_rounded),
  _HabitIconOption(
    key: 'fitness',
    label: 'Train',
    icon: Icons.fitness_center_rounded,
  ),
  _HabitIconOption(
    key: 'meditate',
    label: 'Meditate',
    icon: Icons.self_improvement_rounded,
  ),
  _HabitIconOption(
    key: 'water',
    label: 'Hydrate',
    icon: Icons.water_drop_rounded,
  ),
  _HabitIconOption(key: 'sleep', label: 'Sleep', icon: Icons.bedtime_rounded),
  _HabitIconOption(
    key: 'food',
    label: 'Nutrition',
    icon: Icons.restaurant_rounded,
  ),
  _HabitIconOption(
    key: 'walk',
    label: 'Walk',
    icon: Icons.directions_walk_rounded,
  ),
  _HabitIconOption(
    key: 'journal',
    label: 'Journal',
    icon: Icons.edit_note_rounded,
  ),
  _HabitIconOption(
    key: 'run',
    label: 'Run',
    icon: Icons.directions_run_rounded,
  ),
  _HabitIconOption(
    key: 'bike',
    label: 'Bike',
    icon: Icons.directions_bike_rounded,
  ),
  _HabitIconOption(key: 'swim', label: 'Swim', icon: Icons.pool_rounded),
  _HabitIconOption(
    key: 'stretch',
    label: 'Stretch',
    icon: Icons.accessibility_new_rounded,
  ),
  _HabitIconOption(key: 'study', label: 'Study', icon: Icons.school_rounded),
  _HabitIconOption(
    key: 'focus',
    label: 'Focus',
    icon: Icons.psychology_rounded,
  ),
  _HabitIconOption(
    key: 'music',
    label: 'Music',
    icon: Icons.music_note_rounded,
  ),
  _HabitIconOption(key: 'coding', label: 'Code', icon: Icons.code_rounded),
  _HabitIconOption(
    key: 'clean',
    label: 'Clean',
    icon: Icons.cleaning_services_rounded,
  ),
  _HabitIconOption(
    key: 'meds',
    label: 'Medicine',
    icon: Icons.medication_rounded,
  ),
  _HabitIconOption(
    key: 'vitamins',
    label: 'Vitamins',
    icon: Icons.vaccines_rounded,
  ),
  _HabitIconOption(key: 'sun', label: 'Sunlight', icon: Icons.wb_sunny_rounded),
  _HabitIconOption(
    key: 'screenfree',
    label: 'Screen Free',
    icon: Icons.phone_disabled_rounded,
  ),
  _HabitIconOption(key: 'plan', label: 'Plan', icon: Icons.event_note_rounded),
  _HabitIconOption(key: 'budget', label: 'Budget', icon: Icons.savings_rounded),
  _HabitIconOption(
    key: 'gratitude',
    label: 'Gratitude',
    icon: Icons.favorite_rounded,
  ),
  _HabitIconOption(key: 'family', label: 'Family', icon: Icons.groups_rounded),
  _HabitIconOption(key: 'call', label: 'Call', icon: Icons.call_rounded),
  _HabitIconOption(
    key: 'sleepEarly',
    label: 'Sleep Early',
    icon: Icons.nightlight_round_rounded,
  ),
  _HabitIconOption(
    key: 'noSugar',
    label: 'No Sugar',
    icon: Icons.no_food_rounded,
  ),
  _HabitIconOption(key: 'steps', label: 'Steps', icon: Icons.hiking_rounded),
  _HabitIconOption(
    key: 'stretchBreak',
    label: 'Break',
    icon: Icons.timer_rounded,
  ),
];

const List<String> _habitColorHexOptions = <String>[
  '#1C7C54',
  '#16A34A',
  '#84CC16',
  '#CA8A04',
  '#EA580C',
  '#DC2626',
  '#BE123C',
  '#DB2777',
  '#A21CAF',
  '#7C3AED',
  '#4338CA',
  '#2563EB',
  '#0284C7',
  '#5D4037',
  '#0E7490',
  '#0F766E',
];

final Map<String, IconData> _habitIconByKey = <String, IconData>{
  for (final _HabitIconOption option in _habitIconOptions)
    option.key: option.icon,
};

IconData _iconForKey(final String iconKey) {
  return _habitIconByKey[iconKey] ?? Icons.track_changes_rounded;
}

String _formatDayCount(final int dayCount) {
  if (dayCount == 1) {
    return '1 day';
  }
  return '$dayCount days';
}

String _formatCount(
  final int count, {
  required final String singularNoun,
  required final String pluralNoun,
}) {
  final String noun = count == 1 ? singularNoun : pluralNoun;
  return '$count $noun';
}

String _generateHabitId() {
  return 'habit_${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

Color _colorFromHex(final String hexColor) {
  final String? normalized = _canonicalHexColorOrNull(hexColor);
  if (normalized == null) {
    return AppColors.brand;
  }

  final int rgb = int.parse(normalized.substring(1), radix: 16);
  return Color(0xFF000000 | rgb);
}

String _hexFromColor(final Color color) {
  final int rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color _foregroundFor(final Color backgroundColor) {
  final double blackContrast = _contrastRatio(Colors.black, backgroundColor);
  final double whiteContrast = _contrastRatio(Colors.white, backgroundColor);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

double _contrastRatio(final Color foreground, final Color background) {
  final Color blendedForeground = foreground.a == 1
      ? foreground
      : Color.alphaBlend(foreground, background);
  final double foregroundLuminance = blendedForeground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double lighter = math.max(foregroundLuminance, backgroundLuminance);
  final double darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

String _normalizeStoredColorHex(
  final String? colorHex, {
  required final String fallback,
}) {
  if (colorHex == null || colorHex.trim().isEmpty) {
    return fallback;
  }
  return _canonicalHexColorOrNull(colorHex) ?? colorHex.trim().toUpperCase();
}

String? _canonicalHexColorOrNull(final String raw) {
  final String normalized = raw.trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }
  final String stripped = normalized.startsWith('#')
      ? normalized.substring(1)
      : normalized;
  if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(stripped)) {
    return null;
  }
  return '#$stripped';
}

String _formatBackdateDateLabel(final DateTime localDate) {
  final String year = localDate.year.toString().padLeft(4, '0');
  final String month = localDate.month.toString().padLeft(2, '0');
  final String day = localDate.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _systemNow() => DateTime.now();
