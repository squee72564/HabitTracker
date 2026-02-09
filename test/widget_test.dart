import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/presentation/presentation.dart';

void main() {
  testWidgets('renders stage 0 app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());

    expect(find.text('Habit Tracker'), findsOneWidget);
    expect(find.text('Foundation Ready'), findsOneWidget);
    expect(
      find.textContaining('theme tokens, logging, and global error handling'),
      findsOneWidget,
    );
  });
}
