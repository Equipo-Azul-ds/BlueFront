import 'package:Trivvy/features/Administrador/Presentacion/Widget/UserListItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> presionoElBotonBloquearDelUsuarioJuanPerez(WidgetTester tester) async {
  // 1. Buscamos el widget de lista que pertenece a Juan Perez
  final userItem = find.ancestor(
    of: find.text('Juan Perez'),
    matching: find.byType(UserListItem),
  );

  // 2. Buscamos el IconButton que tiene el icono de bloqueo
  // Usamos el icono Icons.lock que es el que definiste para usuarios activos
  final blockButton = find.descendant(
    of: userItem,
    matching: find.byIcon(Icons.lock),
  );

  await tester.tap(blockButton);
  await tester.pumpAndSettle();
}