import 'package:Trivvy/features/Administrador/Aplication/UseCases/DeleteUserUseCase.dart';
import 'package:Trivvy/features/Administrador/Aplication/UseCases/GetUserListUseCase.dart';
import 'package:Trivvy/features/Administrador/Aplication/UseCases/ToggleAdminUseCase.dart';
import 'package:Trivvy/features/Administrador/Aplication/UseCases/ToggleUserStatusUseCase.dart';
import 'package:Trivvy/features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';
import 'package:Trivvy/features/Administrador/Presentacion/pages/UserManagementPage.dart';
import 'package:Trivvy/features/Administrador/Presentacion/provider/UserManagementProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

Future<void> abroLaPaginaDeGestionDeUsuarios(WidgetTester tester) async {
  final getIt = GetIt.instance;

  // 1. Registro de UseCases en GetIt (si no están registrados ya)
  // Esto evita el error de "Missing Dependency" al crear el Provider
  _registerUseCasesIfMissing(getIt);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider<UserManagementProvider>(
        create: (_) => UserManagementProvider(
          getUserListUseCase: getIt<GetUserListUseCase>(),
          toggleUserStatusUseCase: getIt<ToggleUserStatusUseCase>(),
          toggleAdminRoleUseCase: getIt<ToggleAdminRoleUseCase>(),
          deleteUserUseCase: getIt<DeleteUserUseCase>(),
        ),
        child: const UserManagementPage(),
      ),
    ),
  );

  // pumpAndSettle es vital para esperar que el initState (loadUsers) termine
  await tester.pumpAndSettle();
}

void _registerUseCasesIfMissing(GetIt getIt) {
  // Aseguramos que el repositorio mockeado en el paso anterior esté disponible
  final repository = getIt<IUserRepository>();

  if (!getIt.isRegistered<GetUserListUseCase>()) {
    getIt.registerLazySingleton(() => GetUserListUseCase(repository));
  }
  if (!getIt.isRegistered<ToggleUserStatusUseCase>()) {
    getIt.registerLazySingleton(() => ToggleUserStatusUseCase(repository));
  }
  if (!getIt.isRegistered<ToggleAdminRoleUseCase>()) {
    getIt.registerLazySingleton(() => ToggleAdminRoleUseCase(repository));
  }
  if (!getIt.isRegistered<DeleteUserUseCase>()) {
    getIt.registerLazySingleton(() => DeleteUserUseCase(repository));
  }
}
