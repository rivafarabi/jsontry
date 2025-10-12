import 'package:flutter_test/flutter_test.dart';

import 'package:jsontry/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JsonTryApp());

    // Verify that our counter starts at zero.
    expect(find.text('0'), findsNothing);
    expect(find.text('No JSON file loaded'), findsOneWidget);
  });
}
