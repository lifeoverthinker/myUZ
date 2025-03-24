import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_uz/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Add debug prints to see the widget tree
    debugDumpApp();

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget, reason: 'Initial counter value should be 0');
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing, reason: 'Counter value should not be 0 after increment');
    expect(find.text('1'), findsOneWidget, reason: 'Counter value should be 1 after increment');
  });
}