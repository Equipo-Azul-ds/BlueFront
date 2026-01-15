import 'package:flutter_test/flutter_test.dart';

/// Usage: debería ver al usuario "Admin Trivvy" con el rol "Administrador"
Future<void> deberiaVerAlUsuarioAdminTrivvyConElRolAdministrador(WidgetTester tester) async {
  expect(find.text('Admin Trivvy'), findsOneWidget);

  // Verificamos que aparezca la etiqueta de Administrador
  expect(find.textContaining('Administrador'), findsAtLeastNWidgets(1));
}
