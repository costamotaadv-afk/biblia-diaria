// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:biblia_diaria/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BibliaApp é construído corretamente', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BibliaApp());

    // The app builds without throwing and renders the Scaffold with the
    // "Bíblia Diária" title in the AppBar.
    expect(find.byType(Scaffold), findsWidgets);
  });
}

