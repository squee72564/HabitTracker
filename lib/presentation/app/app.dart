import 'package:flutter/material.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/presentation/home/home_screen.dart';

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
