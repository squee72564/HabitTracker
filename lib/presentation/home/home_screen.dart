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
      final int bestStreak = calculatePositiveBestStreak(events: events);
      return _HabitTrackingSnapshot(
        isCompletedToday: isCompletedToday,
        streakLabel:
            'Streak: ${_formatDayCount(currentStreak)} (Best: ${_formatDayCount(bestStreak)})',
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
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
  }

  Future<void> _createHabit() async {
    final _HabitFormResult? result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (final BuildContext context) {
        return _HabitFormDialog(
          existingHabitNames: _habits.map((final Habit h) => h.name),
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

    await _saveHabit(habit: habit, successMessage: 'Habit created.');
  }

  Future<void> _editHabit(final Habit habit) async {
    final _HabitFormResult? result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (final BuildContext context) {
        return _HabitFormDialog(
          initialHabit: habit,
          existingHabitNames: _habits.map((final Habit h) => h.name),
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

    await _saveHabit(habit: updatedHabit, successMessage: 'Habit updated.');
  }

  Future<void> _saveHabit({
    required final Habit habit,
    required final String successMessage,
  }) async {
    try {
      await widget.habitRepository.saveHabit(habit);
      await _loadHabits();
      if (!mounted) {
        return;
      }
      _showSnackBar(successMessage);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to save habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not save habit.');
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
        await _logRelapseAtLocalDateTime(
          habit: habit,
          localDateTime: widget.clock(),
          feedbackMessage: 'Relapse logged.',
        );
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
    final String todayLocalDayKey = toLocalDayKey(nowLocal);
    final List<HabitEvent> eventsOnDay = await widget.habitEventRepository
        .listEventsForHabitOnDay(
          habitId: habit.id,
          localDayKey: todayLocalDayKey,
        );
    final List<HabitEvent> completionEvents = eventsOnDay
        .where(
          (final HabitEvent event) =>
              event.eventType == HabitEventType.complete,
        )
        .toList(growable: false);

    if (completionEvents.isNotEmpty) {
      final HabitEvent eventToDelete = completionEvents.last;
      await widget.habitEventRepository.deleteEventById(eventToDelete.id);
      await _refreshTrackingForHabit(habit);
      if (!mounted) {
        return;
      }
      _showSnackBar('Today marked as not done.');
      return;
    }

    final HabitEvent completion = HabitEvent(
      id: _generateHabitEventId(),
      habitId: habit.id,
      eventType: HabitEventType.complete,
      occurredAtUtc: nowLocal.toUtc(),
      localDayKey: todayLocalDayKey,
      tzOffsetMinutesAtEvent: captureTzOffsetMinutesAtEvent(nowLocal),
    );

    try {
      await widget.habitEventRepository.saveEvent(completion);
    } on DuplicateHabitCompletionException {
      await _refreshTrackingForHabit(habit);
      if (!mounted) {
        return;
      }
      _showSnackBar('Already marked done for today.');
      return;
    }

    await _refreshTrackingForHabit(habit);
    if (!mounted) {
      return;
    }
    _showSnackBar('Marked done for today.');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final List<String> weekdayLabels = _weekdayLabelsForWeekStart(
      _appSettings.weekStart,
    );

    return Column(
      children: <Widget>[
        _MonthNavigationBar(
          visibleMonth: _visibleMonth,
          isViewingCurrentMonth: isViewingCurrentMonth,
          onPreviousMonth: _showPreviousMonth,
          onNextMonth: _showNextMonth,
          onJumpToCurrentMonth: _jumpToCurrentMonth,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _GridLegend(),
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
                weekdayLabels: weekdayLabels,
                onQuickAction: () => _onQuickActionTap(habit),
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

  String _fallbackStreakSummary(final Habit habit) {
    return habit.mode == HabitMode.positive
        ? 'Streak: 0 days (Best: 0 days)'
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

class _GridLegend extends StatelessWidget {
  const _GridLegend();

  @override
  Widget build(final BuildContext context) {
    return Container(
      key: const Key('home_grid_legend'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Legend', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _LegendItem(
                tooltip: 'Positive: completed for that day',
                color: Color(0xFF2E7D32),
                label: 'Done',
              ),
              _LegendItem(
                tooltip: 'Positive: no completion logged for that day',
                color: Color(0xFFF2B8B5),
                label: 'Missed',
              ),
              _LegendItem(
                tooltip: 'Future day for both habit modes',
                color: Color(0xFFE8EAE6),
                label: 'Future',
              ),
              _LegendItem(
                tooltip: 'Negative: relapse logged on that day',
                color: Color(0xFFC62828),
                label: 'Relapse',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.tooltip,
    required this.color,
    required this.label,
  });

  final String tooltip;
  final Color color;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
    required this.isTrackingActionInProgress,
    required this.monthlyCells,
    required this.weekdayLabels,
    required this.onQuickAction,
    required this.onEdit,
    required this.onBackdateRelapse,
    required this.onArchive,
  });

  final Habit habit;
  final String streakSummary;
  final bool isCompletedToday;
  final bool isTrackingActionInProgress;
  final List<HabitMonthCell> monthlyCells;
  final List<String> weekdayLabels;
  final Future<void> Function() onQuickAction;
  final Future<void> Function() onEdit;
  final Future<void> Function() onBackdateRelapse;
  final Future<void> Function() onArchive;

  @override
  Widget build(final BuildContext context) {
    final Color cardColor = _colorFromHex(habit.colorHex);
    final Color textColor = _foregroundFor(cardColor);

    final String modeLabel = habit.mode == HabitMode.positive
        ? 'Positive habit'
        : 'Negative habit';
    final String currentSummary = habit.mode == HabitMode.positive
        ? '$streakSummary • ${isCompletedToday ? 'Done today' : 'Not done today'}'
        : streakSummary;

    final IconData quickActionIcon = switch (habit.mode) {
      HabitMode.positive =>
        isCompletedToday ? Icons.undo_rounded : Icons.check_circle_rounded,
      HabitMode.negative => Icons.warning_amber_rounded,
    };
    final String quickActionTooltip = switch (habit.mode) {
      HabitMode.positive => isCompletedToday ? 'Undo today' : 'Mark done today',
      HabitMode.negative => 'Log relapse now',
    };

    return Card(
      color: cardColor,
      margin: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            leading: CircleAvatar(
              backgroundColor: textColor.withValues(alpha: 0.2),
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
                  ).textTheme.bodySmall?.copyWith(color: textColor),
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
                if (habit.note != null && habit.note!.isNotEmpty)
                  Text(
                    habit.note!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  key: ValueKey<String>('habit_card_quick_action_${habit.id}'),
                  onPressed: isTrackingActionInProgress ? null : onQuickAction,
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
                        key: ValueKey<String>('habit_card_archive_${habit.id}'),
                        value: _HabitCardMenuAction.archive,
                        child: const Text('Archive Habit'),
                      ),
                    ];
                  },
                ),
              ],
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
              mode: habit.mode,
              textColor: textColor,
              weekdayLabels: weekdayLabels,
            ),
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
    required this.mode,
    required this.textColor,
    required this.weekdayLabels,
  });

  final String habitId;
  final List<HabitMonthCell> cells;
  final HabitMode mode;
  final Color textColor;
  final List<String> weekdayLabels;

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
            Text(
              mode == HabitMode.positive
                  ? 'Monthly consistency'
                  : 'Monthly relapse markers',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor.withValues(alpha: 0.95),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: List<Widget>.generate(weekdayLabels.length, (
                final int index,
              ) {
                final String label = weekdayLabels[index];
                return Expanded(
                  child: Text(
                    label,
                    key: ValueKey<String>(
                      'habit_grid_weekday_${habitId}_$index',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cells
                  .map((final HabitMonthCell cell) {
                    return _HabitMonthCell(
                      habitId: habitId,
                      cell: cell,
                      cellSize: cellSize,
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
    required this.cellSize,
  });

  final String habitId;
  final HabitMonthCell cell;
  final double cellSize;

  @override
  Widget build(final BuildContext context) {
    final _MonthCellVisual visual = _visualForCell(context, cell);
    final bool showDayNumber = cell.isInMonth && cellSize >= 19;
    return Tooltip(
      message: '${cell.localDayKey}: ${visual.tooltipLabel}',
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
    );
  }
}

_MonthCellVisual _visualForCell(
  final BuildContext context,
  final HabitMonthCell cell,
) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final HabitSemanticColors semanticColors = context.semanticColors;
  return switch (cell.state) {
    HabitMonthCellState.positiveDone => _MonthCellVisual(
      backgroundColor: semanticColors.positive,
      borderColor: semanticColors.positive.withValues(alpha: 0.9),
      textColor: Colors.white,
      alpha: 0.9,
      borderWidth: 1,
      tooltipLabel: 'Done',
    ),
    HabitMonthCellState.positiveMissed => _MonthCellVisual(
      backgroundColor: semanticColors.negative.withValues(alpha: 0.2),
      borderColor: semanticColors.negative.withValues(alpha: 0.65),
      textColor: colorScheme.onSurface,
      alpha: 0.9,
      borderWidth: 1,
      tooltipLabel: 'Missed',
    ),
    HabitMonthCellState.positiveFuture => _MonthCellVisual(
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.outlineVariant,
      textColor: colorScheme.onSurfaceVariant,
      alpha: 0.35,
      borderWidth: 1,
      tooltipLabel: 'Future',
    ),
    HabitMonthCellState.negativeRelapse => _MonthCellVisual(
      backgroundColor: colorScheme.surface,
      borderColor: semanticColors.negative,
      textColor: colorScheme.onSurface,
      alpha: 0.85,
      borderWidth: 1.2,
      tooltipLabel: 'Relapse',
      showRelapseDot: true,
      dotColor: semanticColors.negative,
    ),
    HabitMonthCellState.negativeClear => _MonthCellVisual(
      backgroundColor: semanticColors.positive.withValues(alpha: 0.2),
      borderColor: semanticColors.positive.withValues(alpha: 0.45),
      textColor: colorScheme.onSurface,
      alpha: 0.8,
      borderWidth: 1,
      tooltipLabel: 'No relapse',
    ),
    HabitMonthCellState.negativeFuture => _MonthCellVisual(
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.outlineVariant,
      textColor: colorScheme.onSurfaceVariant,
      alpha: 0.35,
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
  const _HabitFormDialog({required this.existingHabitNames, this.initialHabit});

  final Habit? initialHabit;
  final Iterable<String> existingHabitNames;

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

  bool get _isEditing => widget.initialHabit != null;

  @override
  void initState() {
    super.initState();

    final Habit? initialHabit = widget.initialHabit;
    _nameController = TextEditingController(text: initialHabit?.name ?? '');
    _noteController = TextEditingController(text: initialHabit?.note ?? '');

    final String initialColorHex =
        (initialHabit?.colorHex ?? _habitColorHexOptions.first).toUpperCase();

    _selectedIconKey = _habitIconByKey.containsKey(initialHabit?.iconKey)
        ? initialHabit!.iconKey
        : _habitIconOptions.first.key;
    _selectedColorHex = _habitColorHexOptions.contains(initialColorHex)
        ? initialColorHex
        : _habitColorHexOptions.first;
    _selectedMode = initialHabit?.mode ?? HabitMode.positive;
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
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _habitIconOptions
                      .map((final _HabitIconOption option) {
                        return ChoiceChip(
                          key: ValueKey<String>(
                            'habit_form_icon_${option.key}',
                          ),
                          avatar: Icon(option.icon, size: 18),
                          label: Text(option.label),
                          selected: _selectedIconKey == option.key,
                          onSelected: (final bool selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _selectedIconKey = option.key;
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
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
                    child: Row(
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
                        const SizedBox(width: AppSpacing.sm),
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

  void _submit() {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String noteText = _noteController.text.trim();
    Navigator.of(context).pop(
      _HabitFormResult(
        name: _nameController.text.trim(),
        iconKey: _selectedIconKey,
        colorHex: _selectedColorHex,
        mode: _selectedMode,
        note: noteText.isEmpty ? null : noteText,
      ),
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
  });

  final String name;
  final String iconKey;
  final String colorHex;
  final HabitMode mode;
  final String? note;
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
];

const List<String> _habitColorHexOptions = <String>[
  '#1C7C54',
  '#255F85',
  '#6A4C93',
  '#8A2D3B',
  '#B85C00',
  '#2E7D32',
  '#1565C0',
  '#5D4037',
];

const List<String> _mondayWeekdayLabels = <String>[
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
  'S',
];
const List<String> _sundayWeekdayLabels = <String>[
  'S',
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
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

String _generateHabitId() {
  return 'habit_${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

Color _colorFromHex(final String hexColor) {
  final String normalized = hexColor.trim().replaceFirst('#', '').toUpperCase();
  if (normalized.length != 6) {
    return AppColors.brand;
  }

  final int? rgb = int.tryParse(normalized, radix: 16);
  if (rgb == null) {
    return AppColors.brand;
  }

  return Color(0xFF000000 | rgb);
}

Color _foregroundFor(final Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.45
      ? Colors.black
      : Colors.white;
}

String _formatBackdateDateLabel(final DateTime localDate) {
  final String year = localDate.year.toString().padLeft(4, '0');
  final String month = localDate.month.toString().padLeft(2, '0');
  final String day = localDate.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _systemNow() => DateTime.now();

List<String> _weekdayLabelsForWeekStart(final AppWeekStart weekStart) {
  return switch (weekStart) {
    AppWeekStart.monday => _mondayWeekdayLabels,
    AppWeekStart.sunday => _sundayWeekdayLabels,
  };
}
