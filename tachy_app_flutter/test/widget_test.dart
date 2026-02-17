// Basic Flutter widget test for Tachy App.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tachy_app_flutter/providers/ppg_provider.dart';
import 'package:tachy_app_flutter/screens/home_screen.dart';

void main() {
  testWidgets('App loads and shows Connect button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PpgProvider(),
        child: MaterialApp(
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('PPG Voltage (Last 5 Seconds)'), findsOneWidget);
  });
}
