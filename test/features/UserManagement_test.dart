// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['optionalTypeArgs'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'step/UserManagament/que_el_administrador_ha_iniciado_sesion.dart';
import 'step/UserManagament/existen_usuarios_registrados_en_el_sistema.dart';
import 'step/UserManagament/abro_la_pagina_de_gestion_de_usuarios.dart';
import 'step/UserManagament/deberia_ver_al_usuario_juan_perez_con_el_rol_usuario.dart';
import 'step/UserManagament/deberia_ver_al_usuario_admin_trivvy_con_el_rol_administrador.dart';
import 'step/UserManagament/presiono_el_boton_dar_privilegios_del_usuario_juan_perez.dart';
import 'step/UserManagament/confirmo_el_cambio_en_el_dialogo.dart';
import 'step/UserManagament/el_usuario_juan_perez_deberia_figurar_como_administrador.dart' hide deberiaVerAlUsuarioAdminTrivvyConElRolAdministrador;
import 'step/UserManagament/presiono_el_boton_bloquear_del_usuario_juan_perez.dart';
import 'step/UserManagament/el_usuario_juan_perez_deberia_figurar_como_bloqueado.dart';

void main() {
  group('''Gestión de Usuarios por el Administrador''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await queElAdministradorHaIniciadoSesion(tester);
      await existenUsuariosRegistradosEnElSistema(tester);
    }

    testWidgets('''Visualizar lista de usuarios''', (tester) async {
      await bddSetUp(tester);
      await abroLaPaginaDeGestionDeUsuarios(tester);
      await deberiaVerAlUsuarioJuanPerezConElRolUsuario(tester);
      await deberiaVerAlUsuarioAdminTrivvyConElRolAdministrador(tester);
    });
    testWidgets('''Cambiar el rol de un usuario a administrador''',
        (tester) async {
      await bddSetUp(tester);
      await abroLaPaginaDeGestionDeUsuarios(tester);
      await presionoElBotonDarPrivilegiosDelUsuarioJuanPerez(tester);
      await confirmoElCambioEnElDialogo(tester);
      await elUsuarioJuanPerezDeberiaFigurarComoAdministrador(tester);
    });
    testWidgets('''Cambiar el estado de un usuario a bloqueado''',
        (tester) async {
      await bddSetUp(tester);
      await abroLaPaginaDeGestionDeUsuarios(tester);
      await presionoElBotonBloquearDelUsuarioJuanPerez(tester);
      await confirmoElCambioEnElDialogo(tester);
      await elUsuarioJuanPerezDeberiaFigurarComoBloqueado(tester);
    });
  });
}
