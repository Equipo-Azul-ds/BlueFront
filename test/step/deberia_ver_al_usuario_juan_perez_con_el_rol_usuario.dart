import 'package:flutter_test/flutter_test.dart';

/// Usage: debería ver al usuario "Juan Perez" con el rol "Usuario"
Future<void> deberiaVerAlUsuarioJuanPerezConElRolUsuario(WidgetTester tester) async {
  // Verificamos que el nombre aparezca en la lista
  expect(find.text('Juan Perez'), findsOneWidget);

  // Verificamos que el rol (UserType) se muestre correctamente. 
  // Nota: Si tu UI traduce 'user' a 'Usuario', buscamos 'Usuario'.
  expect(find.textContaining('Usuario'), findsAtLeastNWidgets(1));
}
