import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_drive/main.dart';
import 'package:car_drive/app_state.dart';

void main() {
  setUp(() {
    AppState.instance.isLocked.value = true;
    AppState.instance.selectedTab.value = 0;
    AppState.instance.themeMode.value = ThemeMode.system;
  });

  testWidgets('App loads and displays main navigation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify AppBar title is present on Home tab
    expect(find.text('Car Telematics'), findsOneWidget);

    // Verify Bottom Navigation Bar tabs
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Live Map'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);

    // Verify Vehicle title/card details
    expect(find.text('Tesla Model 3'), findsOneWidget);
    expect(find.text('Telemetry & Health'), findsOneWidget);
  });

  testWidgets('Navigation tab switching works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Switch to Services tab
    await tester.tap(find.text('Services'));
    await tester.pump();

    expect(find.text('Service Network'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search bar

    // Switch back to Dashboard tab
    await tester.tap(find.text('Dashboard'));
    await tester.pump();

    expect(find.text('Tesla Model 3'), findsOneWidget);
  });

  testWidgets('Lock toggle updates state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Vehicle Secured'), findsOneWidget);

    // Tap Unlock button
    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(AppState.instance.isLocked.value, false);
    expect(find.text('Vehicle Unlocked'), findsAtLeastNWidgets(1));
  });
}
