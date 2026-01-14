// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sports_counter/main.dart';

void main() {
  testWidgets('Home score increments', (WidgetTester tester) async {
    await tester.pumpWidget(const ScoreApp());

    // Two teams should start at 0 points each
    expect(find.text('0'), findsNWidgets(2));

    // Tap the first +1 button (home team)
    await tester.tap(find.text('+1').first);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
