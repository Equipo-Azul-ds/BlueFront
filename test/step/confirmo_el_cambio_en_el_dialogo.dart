import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> confirmoElCambioEnElDialogo(WidgetTester tester) async {
  // Tu página tiene botones que dicen 'Dar privilegios', 'Bloquear', etc. dentro del diálogo
  // Pero el botón de acción principal en tus diálogos es un ElevatedButton
  final botonConfirmar = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(ElevatedButton),
  );

  await tester.tap(botonConfirmar);
  await tester.pumpAndSettle(); // Importante para que la animación del diálogo termine
}