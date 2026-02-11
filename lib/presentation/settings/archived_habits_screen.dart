import 'package:flutter/material.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';

class ArchivedHabitsScreen extends StatefulWidget {
  const ArchivedHabitsScreen({
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
  State<ArchivedHabitsScreen> createState() => _ArchivedHabitsScreenState();
}

class _ArchivedHabitsScreenState extends State<ArchivedHabitsScreen> {
  final AppLogger _logger = AppLogger.instance;

  List<Habit> _archivedHabits = <Habit>[];
  Map<String, HabitReminder> _remindersByHabitId = <String, HabitReminder>{};
  AppSettings _settings = AppSettings.defaults;
  Set<String> _busyHabitIds = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArchivedHabits();
  }

  Future<void> _loadArchivedHabits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.notificationScheduler.initialize();
      final AppSettings settings = await widget.appSettingsRepository
          .loadSettings();
      final List<Habit> allHabits = await widget.habitRepository.listHabits();
      final List<HabitReminder> reminders = await widget.habitReminderRepository
          .listReminders();
      if (!mounted) {
        return;
      }

      final List<Habit> archivedHabits =
          allHabits
              .where((final Habit habit) => habit.isArchived)
              .toList(growable: false)
            ..sort(
              (final Habit a, final Habit b) =>
                  b.archivedAtUtc!.compareTo(a.archivedAtUtc!),
            );

      setState(() {
        _settings = settings;
        _archivedHabits = archivedHabits;
        _remindersByHabitId = <String, HabitReminder>{
          for (final HabitReminder reminder in reminders)
            reminder.habitId: reminder,
        };
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to load archived habits.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load archived habits. Please try again.';
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived habits')),
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
                onPressed: _loadArchivedHabits,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_archivedHabits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No archived habits.',
                key: Key('archived_habits_empty_state'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _archivedHabits.length,
      separatorBuilder: (final BuildContext context, final int index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (final BuildContext context, final int index) {
        final Habit habit = _archivedHabits[index];
        return _buildArchivedHabitCard(context, habit);
      },
    );
  }

  Widget _buildArchivedHabitCard(
    final BuildContext context,
    final Habit habit,
  ) {
    final bool isBusy = _busyHabitIds.contains(habit.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Archived on ${_formatArchivedDate(habit)}'),
              trailing: Icon(
                Icons.archive_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey<String>(
                      'archived_unarchive_button_${habit.id}',
                    ),
                    onPressed: isBusy ? null : () => _unarchiveHabit(habit),
                    child: const Text('Unarchive'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: ValueKey<String>('archived_delete_button_${habit.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: isBusy
                        ? null
                        : () => _deleteHabitPermanently(habit),
                    child: const Text('Delete permanently'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unarchiveHabit(final Habit habit) async {
    if (_busyHabitIds.contains(habit.id)) {
      return;
    }
    _setHabitBusy(habit.id, isBusy: true);

    try {
      await widget.habitRepository.unarchiveHabit(habit.id);
      final HabitReminder? reminder = _remindersByHabitId[habit.id];
      if (_settings.remindersEnabled &&
          reminder != null &&
          reminder.isEnabled) {
        final bool notificationsAllowed = await widget.notificationScheduler
            .areNotificationsAllowed();
        if (notificationsAllowed) {
          await widget.notificationScheduler.scheduleDailyReminder(
            habitId: habit.id,
            habitName: habit.name,
            reminderTimeMinutes: reminder.reminderTimeMinutes,
          );
        }
      } else {
        await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _archivedHabits = _archivedHabits
            .where((final Habit archivedHabit) => archivedHabit.id != habit.id)
            .toList(growable: false);
      });
      _showSnackBar('Habit unarchived.');
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to unarchive habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackBar('Could not unarchive habit.');
      }
    } finally {
      _setHabitBusy(habit.id, isBusy: false);
    }
  }

  Future<void> _deleteHabitPermanently(final Habit habit) async {
    if (_busyHabitIds.contains(habit.id)) {
      return;
    }

    final bool confirmed = await _confirmPermanentDelete(habit);
    if (!confirmed) {
      return;
    }

    _setHabitBusy(habit.id, isBusy: true);
    try {
      await widget.habitRepository.deleteHabitPermanently(habit.id);
      await widget.notificationScheduler.cancelReminder(habitId: habit.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _archivedHabits = _archivedHabits
            .where((final Habit archivedHabit) => archivedHabit.id != habit.id)
            .toList(growable: false);
        _remindersByHabitId = <String, HabitReminder>{..._remindersByHabitId}
          ..remove(habit.id);
      });
      _showSnackBar('Habit permanently deleted.');
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Failed to permanently delete habit ${habit.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackBar('Could not delete habit.');
      }
    } finally {
      _setHabitBusy(habit.id, isBusy: false);
    }
  }

  Future<bool> _confirmPermanentDelete(final Habit habit) async {
    String confirmationText = '';
    bool canConfirm = false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (final BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                final BuildContext context,
                final void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  title: const Text('Delete permanently?'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'This permanently deletes "${habit.name}" and all related local history.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Type ${habit.name} to confirm.'),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          key: ValueKey<String>(
                            'archived_delete_confirmation_field_${habit.id}',
                          ),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(labelText: habit.name),
                          onChanged: (final String value) {
                            setDialogState(() {
                              confirmationText = value.trim();
                              canConfirm = confirmationText == habit.name;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      key: ValueKey<String>(
                        'archived_delete_cancel_button_${habit.id}',
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      key: ValueKey<String>(
                        'archived_delete_confirm_button_${habit.id}',
                      ),
                      onPressed: canConfirm
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
        );
      },
    );

    return confirmed ?? false;
  }

  String _formatArchivedDate(final Habit habit) {
    final DateTime archivedAtLocal = habit.archivedAtUtc!.toLocal();
    final String year = archivedAtLocal.year.toString().padLeft(4, '0');
    final String month = archivedAtLocal.month.toString().padLeft(2, '0');
    final String day = archivedAtLocal.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _setHabitBusy(final String habitId, {required final bool isBusy}) {
    if (!mounted) {
      return;
    }
    setState(() {
      final Set<String> updatedBusyIds = <String>{..._busyHabitIds};
      if (isBusy) {
        updatedBusyIds.add(habitId);
      } else {
        updatedBusyIds.remove(habitId);
      }
      _busyHabitIds = updatedBusyIds;
    });
  }

  void _showSnackBar(final String message) {
    showTransientFeedback(context, message);
  }
}
