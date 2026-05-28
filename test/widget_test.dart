import 'package:flutter_test/flutter_test.dart';
import 'package:lexoraai/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Splash screen visual smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LexoraApp(initialThemeMode: ThemeMode.system));

    // Verify that Splash screen title is rendering
    expect(find.text('LexoraAI'), findsOneWidget);
  });
}
