import 'package:flutter/widgets.dart';

import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/presentation/presentation.dart';

void main() {
  AppErrorBoundary.bootstrap(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const HabitTrackerApp());
  });
}
