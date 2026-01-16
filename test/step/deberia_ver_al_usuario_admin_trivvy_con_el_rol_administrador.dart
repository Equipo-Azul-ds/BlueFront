import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> deberiaVerAlUsuarioAdminTrivvyConElRolAdministrador(WidgetTester tester) async {

  await tester.pumpAndSettle();

  // Ahora buscamos
  expect(find.text('Admin Trivvy'), findsOneWidget);


  // Verificamos que tenga el icono de Administrador activo
  expect(find.byIcon(Icons.admin_panel_settings), findsAtLeastNWidgets(1));
}
