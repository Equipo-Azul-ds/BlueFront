import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: debería ver al usuario "Admin Trivvy" con el rol "Administrador"
Future<void> elUsuarioJuanPerezDeberiaFigurarComoAdministrador(WidgetTester tester) async {
  expect(find.text('Juan Perez'), findsOneWidget);

  // Verificamos que aparezca la etiqueta de Administrador
  expect(find.byIcon(Icons.admin_panel_settings), findsAtLeastNWidgets(1));
}
