import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> ingresoLaPalabraEnElBuscador(WidgetTester tester, String keyword) async {
  // Buscamos el TextField por su hintText definido en discover_page.dart
  final searchField = find.byWidgetPredicate(
          (widget) => widget is TextField && widget.decoration?.hintText == 'Buscar Kahoots'
  );

  await tester.enterText(searchField, keyword);
  // Importante: Tu listener _onSearchChanged necesita que pase un frame
  await tester.pump();
}
