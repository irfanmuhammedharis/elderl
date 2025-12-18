import 'package:elderl/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ElderLApp());

    // Verify that the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen displays welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderLApp());

    // Verify welcome text is displayed
    expect(find.text('Welcome to ElderL'), findsOneWidget);
  });

  testWidgets('Home screen has Get Started button', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderLApp());

    // Verify Get Started button exists
    expect(find.text('Get Started'), findsOneWidget);
  });
}
