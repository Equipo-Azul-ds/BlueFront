import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exception.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/DataSource/IUserDataSource.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';
import '../../Dominio/entidad/User.dart';


class UserRepositoryImpl implements IUserRepository {
  final IUserDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource}) {
    try { print('UserRepositoryImpl initialized'); } catch (_) {}
  }

  @override
  Future<Either<Failure, PaginatedUserList>> getUsers(UserQueryParams params) async {
    try {
      final response = await remoteDataSource.fetchUsers(params);

      final List<UserEntity> users = response.data
          .map((dto) => dto.toEntity())
          .toList();


      final pagination = response.pagination;

      final paginatedList = PaginatedUserList(
        users: users,
        totalCount: pagination?.totalCount ?? users.length,
        totalPages: pagination?.totalPages ?? 1,
        page: pagination?.page ?? 1,
        limit: pagination?.limit ?? 10,
      );

      return Right(paginatedList);
    } on ServerException catch (e, st) {
      print('UserRepositoryImpl.getUsers -> ServerException: ${e.message}');
      print('Stacktrace: $st');
      return Left(NetworkFailure());
    } catch (e, st) {
      print('UserRepositoryImpl.getUsers -> Unexpected Exception: $e');
      print('Stacktrace: $st');
      return Left(UnknownFailure());
    }
  }



  @override
  Future<Either<Failure, UserEntity>> toggleUserStatus(String userId, String currentStatus) async {
    try {
      print('$currentStatus en el repo');
      final user = await remoteDataSource.toggleUserStatus(userId, currentStatus);
      return Right(user);
    } on ServerException catch (e) {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
      return Right(null);
    } catch (e) {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> toggleAdminStatus(String userId, bool currentlyIsAdmin) async {
    try {
      final user = await remoteDataSource.toggleAdminStatus(userId, currentlyIsAdmin);
      return Right(user);
    } on ServerException catch (e) {
      print('UserRepositoryImpl.toggleAdminStatus -> ServerException: ${e.message}');
      return Left(NetworkFailure());
    } catch (e) {
      print('UserRepositoryImpl.toggleAdminStatus -> Unexpected Exception: $e');
      return Left(UnknownFailure());
    }
  }
}
int _safeInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}