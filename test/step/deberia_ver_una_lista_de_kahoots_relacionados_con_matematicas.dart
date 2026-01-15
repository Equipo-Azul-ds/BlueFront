import 'package:flutter_test/flutter_test.dart';

Future<void> deberiaVerUnaLista_DeKahootsRelacionadosConMatematicas(WidgetTester tester) async {
  await tester.pumpAndSettle();

  // 1. Verificamos el título de la sección de resultados
  expect(find.textContaining('Resultados de la búsqueda: "matematicas"'), findsOneWidget);

  // 2. Verificamos que el título del Kahoot mockeado aparezca
  expect(find.text('Matemáticas Avanzadas'), findsOneWidget);
}