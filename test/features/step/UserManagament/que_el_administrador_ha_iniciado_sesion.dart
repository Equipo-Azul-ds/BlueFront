import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';
import 'package:Trivvy/features/Administrador/Dominio/entidad/User.dart';
import 'package:Trivvy/features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';

class MockUserRepository extends Mock implements IUserRepository {}

Future<void> queElAdministradorHaIniciadoSesion(WidgetTester tester) async {
  final getIt = GetIt.instance;

  // Limpiamos registros previos para evitar conflictos
  if (getIt.isRegistered<IUserRepository>()) {
    await getIt.unregister<IUserRepository>();
  }

  final mockRepo = MockUserRepository();

  // Creamos la lista paginada usando tu UserEntity real
  final listaUsuarios = PaginatedUserList(
    users: [
      UserEntity(
        id: '1',
        username: 'juanp',
        name: 'Juan Perez',
        email: 'juan@test.com',
        description: 'Usuario de prueba',
        userType: UserType.user, // Usando tu Enum UserType
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAdmin: false,
        status: UserStatus.active, // Usando tu Enum UserStatus
      ),
      UserEntity(
        id: '2',
        username: 'admintrivvy',
        name: 'Admin Trivvy',
        email: 'admin@trivvy.com',
        description: 'Administrador principal',
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

  // Configuramos el stub para que cualquier consulta de parámetros devuelva esta lista
  when(() => mockRepo.getUsers(any())).thenAnswer((_) async => Right(listaUsuarios));

  // Registramos el mock en GetIt
  getIt.registerSingleton<IUserRepository>(mockRepo);
}