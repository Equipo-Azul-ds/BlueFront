import 'package:flutter_test/flutter_test.dart';

Future<void> deberiaVerLaCategoriaHistoria(WidgetTester tester) async {
  // Verificamos que el widget KahootCategorySection se renderice con el nombre del tema
  expect(find.text('Historia'), findsOneWidget);
}
