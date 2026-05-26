import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maarg/main.dart';

void main() {
  testWidgets('MAARG App Home Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MaargApp()));

    // Verify that the title 'M A A R G' is displayed on the screen.
    expect(find.text('M A A R G'), findsOneWidget);

    // Verify that the REPORT ACCIDENT button is present.
    expect(find.text('REPORT\nACCIDENT'), findsOneWidget);

    // Verify that the Good Samaritan footer is visible.
    expect(find.text('Protected by Good Samaritan Act'), findsOneWidget);
  });
}
