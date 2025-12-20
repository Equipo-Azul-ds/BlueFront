import 'package:dartz/dartz.dart';
// Ajusta tus imports
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exception.dart';
import '../../Aplication/DataSource/IUserDataSource.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';
import '../../Dominio/entidad/User.dart';


class UserRepositoryImpl implements IUserRepository {
  final IUserDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource}) {
    // Log de inicialización consistente con DiscoverRepository.dart
    try { print('UserRepositoryImpl initialized'); } catch (_) {}
  }

  @override
  Future<Either<Failure, PaginatedUserList>> getUsers(UserQueryParams params) async {
    // Log de inicio de operación consistente con DiscoverRepository.dart
    try { print('UserRepositoryImpl.getUsers -> params=${params.toMap()}'); } catch (_) {}

    try {
      final response = await remoteDataSource.fetchUsers(params);

      // Mapear DTOs a Entidades
      final List<UserEntity> users = response.data
          .map((dto) => dto.toEntity())
          .toList();

      // Crear el modelo de lista paginada de Dominio
      final pagination = response.pagination;
      final paginatedList = PaginatedUserList(
        users: users,
        totalCount: pagination['totalCount'] as int,
        totalPages: pagination['totalPages'] as int,
        page: pagination['page'] as int,
        limit: pagination['limit'] as int,
      );

      // Log de éxito consistente con DiscoverRepository.dart
      try { print('UserRepositoryImpl.getUsers -> SUCCESS, ${users.length} users fetched'); } catch (_) {}
      return Right(paginatedList);

    } on ServerException catch (e, st) {
      // Captura de ServerException con StackTrace (Consistente con DiscoverRepository.dart)
      print('UserRepositoryImpl.getUsers -> ServerException: ${e.message}');
      print('Stacktrace: $st');
      // Mapear a NetworkFailure (Consistente con DiscoverRepository.dart)
      return Left(NetworkFailure());
    } catch (e, st) {
      // Captura genérica con StackTrace (Consistente con DiscoverRepository.dart)
      print('UserRepositoryImpl.getUsers -> Unexpected Exception: $e');
      print('Stacktrace: $st');
      // Mapear a UnknownFailure (Consistente con DiscoverRepository.dart)
      return Left(UnknownFailure());
    }
  }

  // Implementaciones dummy para otras operaciones
  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    try {
      await remoteDataSource.blockUser(userId);
      return const Right(null);
    } on ServerException {
      return Left(NetworkFailure());
    } catch (_) {
      return Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
      return const Right(null);
    } on ServerException {
      return Left(NetworkFailure());
    } catch (_) {
      return Left(UnknownFailure());
    }
  }
}