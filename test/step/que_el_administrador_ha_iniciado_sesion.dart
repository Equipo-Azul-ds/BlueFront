import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';

import 'package:Trivvy/features/Administrador/Dominio/entidad/User.dart';
import 'package:Trivvy/features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';
import 'package:Trivvy/features/Administrador/Aplication/dtos/user_query_params.dart';

class MockUserRepository extends Mock implements IUserRepository {}

class UserQueryParamsFake extends Fake implements UserQueryParams {}

Future<void> queElAdministradorHaIniciadoSesion(WidgetTester tester) async {
  final getIt = GetIt.instance;

  // 1. Limpieza total de GetIt para evitar el error "already registered"
  // reset() es la forma más segura en entornos de test.
  await getIt.reset();

  // 2. Registrar el fallback para Mocktail (necesario después del reset)
  registerFallbackValue(UserQueryParamsFake());

  final mockRepo = MockUserRepository();

  // 3. Definición de la data de prueba
  final listaUsuarios = PaginatedUserList(
    users: [
      UserEntity(
        id: '1',
        username: 'juanp',
        name: 'Juan Perez',
        email: 'juan@test.com',
        description: 'Usuario',
        userType: UserType.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAdmin: false,
        status: UserStatus.active,
      ),
      UserEntity(
        id: '2',
        username: 'admintrivvy',
        name: 'Admin Trivvy',
        email: 'admin@trivvy.com',
        description: 'Admin',
        userType: UserType.admin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAdmin: true,
        status: UserStatus.active,
      ),
    ],
    totalCount: 2,
    totalPages: 1,
    page: 1,
    limit: 10,
  );

  final usuarioActualizado = UserEntity(
    id: '1',
    username: 'juanp',
    name: 'Juan Perez',
    email: 'juan@test.com',
    description: 'Usuario',
    userType: UserType.user,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isAdmin: true,
    status: UserStatus.blocked,
  );

  // 4. Configuración de respuestas del Mock
  when(() => mockRepo.getUsers(any())).thenAnswer((_) async => Right(listaUsuarios));
  when(() => mockRepo.toggleAdminStatus(any(), any())).thenAnswer((_) async => Right(usuarioActualizado));
  when(() => mockRepo.toggleUserStatus(any(), any())).thenAnswer((_) async => Right(usuarioActualizado));

  // 5. Registro de la dependencia
  getIt.registerSingleton<IUserRepository>(mockRepo);
}