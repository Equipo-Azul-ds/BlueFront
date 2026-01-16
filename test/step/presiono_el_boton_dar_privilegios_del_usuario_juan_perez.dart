import 'package:Trivvy/features/Administrador/Presentacion/Widget/UserListItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> presionoElBotonDarPrivilegiosDelUsuarioJuanPerez(WidgetTester tester) async {
  final userItem = find.ancestor(
    of: find.text('Juan Perez'),
    matching: find.byType(UserListItem),
  );

  // Buscamos por el icono de persona (cuando no es admin)
  final adminButton = find.descendant(
    of: userItem,
    matching: find.byIcon(Icons.person_outline),
  );

  await tester.tap(adminButton);
  await tester.pumpAndSettle();
}
