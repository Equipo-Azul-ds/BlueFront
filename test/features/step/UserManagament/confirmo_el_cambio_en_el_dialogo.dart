import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: confirmo el cambio en el diálogo
Future<void> confirmoElCambioEnElDialogo(WidgetTester tester) async {
  // Esperamos a que el diálogo termine de animarse
  await tester.pumpAndSettle();

  // Buscamos el botón de confirmación.
  // En tu código usas ElevatedButton para la acción positiva y TextButton para 'Cancelar'
  final confirmButton = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(ElevatedButton),
  );

  expect(confirmButton, findsOneWidget);

  await tester.tap(confirmButton);

  // Importante: pumpAndSettle para procesar el cierre del diálogo y la llamada al provider
  await tester.pumpAndSettle();
}
