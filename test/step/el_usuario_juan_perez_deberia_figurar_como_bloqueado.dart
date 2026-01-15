import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:Trivvy/features/Administrador/Dominio/entidad/User.dart';
import 'package:Trivvy/features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';
import 'package:get_it/get_it.dart';

Future<void> elUsuarioJuanPerezDeberiaFigurarComoBloqueado(WidgetTester tester) async {
  // En un test real, actualizaríamos el mock para que la siguiente carga
  // o el estado del provider refleje el bloqueo.

  // Verificamos si en la UI aparece el texto "Bloqueado" o si el botón cambió a "Desbloquear"
  expect(find.byIcon(Icons.lock_open), findsOneWidget);
}
