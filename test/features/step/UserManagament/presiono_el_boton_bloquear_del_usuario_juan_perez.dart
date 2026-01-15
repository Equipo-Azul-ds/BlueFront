import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> presionoElBotonBloquearDelUsuarioJuanPerez(WidgetTester tester) async {
  // Localizamos el item de Juan Perez
  final userItem = find.ancestor(
    of: find.text('Juan Perez'),
    matching: find.byType(ListTile),
  );

  // Buscamos el botón que contiene el texto "Bloquear"
  final blockButton = find.descendant(
    of: userItem,
    matching: find.text('Bloquear'),
  );

  await tester.tap(blockButton);
  await tester.pumpAndSettle(); // Esperamos a que aparezca el diálogo
}
