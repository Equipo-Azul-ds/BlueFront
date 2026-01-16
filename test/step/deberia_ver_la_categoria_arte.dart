import 'package:flutter_test/flutter_test.dart';

Future<void> deberiaVerLaCategoriaArte(WidgetTester tester) async {
  // Busca específicamente el widget de categoría con el nombre esperado
  expect(find.text('Arte'), findsOneWidget);
}
