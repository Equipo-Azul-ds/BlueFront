import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';
import 'package:Trivvy/features/Administrador/Dominio/entidad/User.dart';
import 'package:Trivvy/features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';

Future<void> existenUsuariosRegistradosEnElSistema(WidgetTester tester) async {
  final mockRepo = GetIt.I<IUserRepository>();

  final listaUsuarios = PaginatedUserList(
    users: [
      UserEntity(
        id: '1',
        username: 'juanp',
        name: 'Juan Perez',
        email: 'juan@test.com',
        description: 'Usuario estándar',
        userType: UserType.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAdmin: false,
        status: UserStatus.active,
      ),
    ],
    totalCount: 1,
    totalPages: 1,
    page: 1,
    limit: 10,
  );

  when(() => mockRepo.getUsers(any())).thenAnswer((_) async => Right(listaUsuarios));
}
