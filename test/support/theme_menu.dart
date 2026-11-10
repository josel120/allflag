import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the three-way theme menu and picks [label] (System/Light/Dark, ES too).
Future<void> chooseTheme(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('theme-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
