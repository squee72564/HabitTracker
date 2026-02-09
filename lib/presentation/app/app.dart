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
    this.database,
  });

  final HabitRepository? habitRepository;
  final HabitEventRepository? habitEventRepository;
  final AppDatabase? database;

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late final HabitRepository _habitRepository;
  late final HabitEventRepository _habitEventRepository;
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
      return;
    }

    if (widget.database != null) {
      _habitRepository = DriftHabitRepository(widget.database!);
      _habitEventRepository = DriftHabitEventRepository(widget.database!);
      return;
    }

    _ownedDatabase = AppDatabase();
    _habitRepository = DriftHabitRepository(_ownedDatabase!);
    _habitEventRepository = DriftHabitEventRepository(_ownedDatabase!);
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
      ),
    );
  }
}
