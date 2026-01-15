import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> presionoElBotonDarPrivilegiosDelUsuarioJuanPerez(WidgetTester tester) async {
  final userItem = find.ancestor(
    of: find.text('Juan Perez'),
    matching: find.byType(ListTile),
  );

  final adminButton = find.descendant(
    of: userItem,
    matching: find.text('Dar privilegios'),
  );

  await tester.tap(adminButton);
  await tester.pumpAndSettle();
}
