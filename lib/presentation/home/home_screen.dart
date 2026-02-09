import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.habitRepository});

  final HabitRepository habitRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppLogger _logger = AppLogger.instance;

  List<Habit> _habits = <Habit>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Habit> habits = await widget.habitRepository
          .listActiveHabits();
      if (!mounted) {
        return;
      }
      setState(() {
        _habits = habits;
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

  void _showSnackBar(final String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
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

    return ListView.separated(
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
          onEdit: () => _editHabit(habit),
          onArchive: () => _archiveHabit(habit),
        );
      },
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
    required this.onEdit,
    required this.onArchive,
  });

  final Habit habit;
  final Future<void> Function() onEdit;
  final Future<void> Function() onArchive;

  @override
  Widget build(final BuildContext context) {
    final Color cardColor = _colorFromHex(habit.colorHex);
    final Color textColor = _foregroundFor(cardColor);

    final String modeLabel = habit.mode == HabitMode.positive
        ? 'Positive habit'
        : 'Negative habit';
    final String subtitle = (habit.note == null || habit.note!.isEmpty)
        ? modeLabel
        : '$modeLabel • ${habit.note}';

    return Card(
      color: cardColor,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
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
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor.withValues(alpha: 0.9),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<_HabitCardMenuAction>(
          key: ValueKey<String>('habit_card_menu_${habit.id}'),
          iconColor: textColor,
          onSelected: (final _HabitCardMenuAction value) {
            switch (value) {
              case _HabitCardMenuAction.edit:
                onEdit();
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
              PopupMenuItem<_HabitCardMenuAction>(
                key: ValueKey<String>('habit_card_archive_${habit.id}'),
                value: _HabitCardMenuAction.archive,
                child: const Text('Archive Habit'),
              ),
            ];
          },
        ),
      ),
    );
  }
}

enum _HabitCardMenuAction { edit, archive }

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

final Map<String, IconData> _habitIconByKey = <String, IconData>{
  for (final _HabitIconOption option in _habitIconOptions)
    option.key: option.icon,
};

IconData _iconForKey(final String iconKey) {
  return _habitIconByKey[iconKey] ?? Icons.track_changes_rounded;
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
