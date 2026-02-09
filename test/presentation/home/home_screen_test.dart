import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/home/home_screen.dart';

void main() {
  group('HomeScreen Stage 3 flows', () {
    testWidgets('creates a habit from empty state', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository();

      await _pumpHomeScreen(tester: tester, repository: repository);

      expect(find.text('No habits yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_create_first_habit_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Read Daily',
      );
      await tester.enterText(
        find.byKey(const Key('habit_form_note_field')),
        '20 minutes before bed',
      );

      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Read Daily'), findsOneWidget);
      expect(find.textContaining('Positive habit'), findsOneWidget);

      final List<Habit> activeHabits = await repository.listActiveHabits();
      expect(activeHabits.length, 1);
      expect(activeHabits.single.note, '20 minutes before bed');
    });

    testWidgets('shows inline validation errors in create form', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'Read',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );

      await _pumpHomeScreen(tester: tester, repository: repository);

      await tester.tap(find.byKey(const Key('home_add_habit_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'read',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name already exists.'), findsOneWidget);

      final String longName = List<String>.filled(
        DomainConstraints.habitNameMaxLength + 1,
        'a',
      ).join();
      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        longName,
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Name must be 1-${DomainConstraints.habitNameMaxLength} characters.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('edits and archives an existing habit', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'Read',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            note: 'Old note',
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );

      await _pumpHomeScreen(tester: tester, repository: repository);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Habit'));
      await tester.pumpAndSettle();

      final TextFormField nameField = tester.widget<TextFormField>(
        find.byKey(const Key('habit_form_name_field')),
      );
      final TextFormField noteField = tester.widget<TextFormField>(
        find.byKey(const Key('habit_form_note_field')),
      );
      expect(nameField.controller?.text, 'Read');
      expect(noteField.controller?.text, 'Old note');

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Read Daily',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Read Daily'), findsOneWidget);
      expect(find.textContaining('Positive habit'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Habit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('archive_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('No habits yet'), findsOneWidget);

      final Habit? archivedHabit = await repository.findHabitById('habit-1');
      expect(archivedHabit, isNotNull);
      expect(archivedHabit?.archivedAtUtc, isNotNull);
    });
  });
}

Future<void> _pumpHomeScreen({
  required final WidgetTester tester,
  required final HabitRepository repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: HomeScreen(habitRepository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeHabitRepository implements HabitRepository {
  _FakeHabitRepository({final Iterable<Habit> seedHabits = const <Habit>[]}) {
    for (final Habit habit in seedHabits) {
      _habitsById[habit.id] = habit;
    }
  }

  final Map<String, Habit> _habitsById = <String, Habit>{};

  @override
  Future<void> saveHabit(final Habit habit) async {
    _habitsById[habit.id] = habit;
  }

  @override
  Future<Habit?> findHabitById(final String habitId) async {
    return _habitsById[habitId];
  }

  @override
  Future<List<Habit>> listHabits({final bool includeArchived = true}) async {
    final List<Habit> allHabits =
        _habitsById.values
            .where((final Habit habit) => includeArchived || !habit.isArchived)
            .toList(growable: false)
          ..sort(
            (final Habit a, final Habit b) =>
                a.createdAtUtc.compareTo(b.createdAtUtc),
          );
    return allHabits;
  }

  @override
  Future<List<Habit>> listActiveHabits() async {
    return listHabits(includeArchived: false);
  }

  @override
  Future<void> archiveHabit({
    required final String habitId,
    required final DateTime archivedAtUtc,
  }) async {
    final Habit? habit = _habitsById[habitId];
    if (habit == null) {
      return;
    }
    _habitsById[habitId] = habit.copyWith(archivedAtUtc: archivedAtUtc);
  }

  @override
  Future<void> unarchiveHabit(final String habitId) async {
    final Habit? habit = _habitsById[habitId];
    if (habit == null) {
      return;
    }
    _habitsById[habitId] = habit.copyWith(clearArchivedAtUtc: true);
  }
}
