// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['optionalTypeArgs'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'step/Discovery/la_api_de_descubrimiento_esta_disponible.dart';
import 'step/Discovery/ingreso_la_palabra_matematicas_en_el_buscador.dart';
import 'step/Discovery/presiono_el_boton_de_busqueda.dart';
import 'step/Discovery/deberia_ver_una_lista_de_kahoots_relacionados_con_matematicas.dart';
import 'step/Discovery/abro_la_pantalla_de_descubrimiento.dart';
import 'step/Discovery/deberia_ver_la_categoria_historia.dart';
import 'step/Discovery/deberia_ver_la_categoria_arte.dart';

void main() {
  group('''Descubrimiento de Kahoots''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await laApiDeDescubrimientoEstaDisponible(tester);
    }

    testWidgets('''Buscar Kahoots por palabra clave''', (tester) async {
      await bddSetUp(tester);
      await ingresoLaPalabraEnElBuscador(tester,'matematicas');
      await presionoElBotonDeBusqueda(tester);
      await deberiaVerUnaLista_DeKahootsRelacionadosConMatematicas(tester);
    });
    testWidgets('''Cargar categorías de exploración al inicio''',
        (tester) async {
      await bddSetUp(tester);
      await abroLaPantallaDeDescubrimiento(tester);
      await deberiaVerLaCategoriaHistoria(tester);
      await deberiaVerLaCategoriaArte(tester);
    });
  });
}
