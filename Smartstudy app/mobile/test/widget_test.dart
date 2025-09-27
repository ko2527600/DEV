// AcademiaFlow Widget Tests
//
// This file contains widget tests for the AcademiaFlow educational platform.
// These tests verify that the UI components work correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartstudy/main.dart';

void main() {
  testWidgets('AcademiaFlow app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AcademiaFlowApp()));

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the AcademiaFlow app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AcademiaFlowApp()));

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Find the MaterialApp widget and check its title
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('AcademiaFlow'));
  });
}
