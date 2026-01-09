// Usaremos 'Either' para manejar errores (Failure) o éxito (Success)
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart'; // Asume un tipo de error base
import '../../Aplication/dtos/user_query_params.dart';
import '../entidad/User.dart';


abstract class IUserRepository {

  Future<Either<Failure, PaginatedUserList>> getUsers(UserQueryParams params);
  Future<Either<Failure, UserEntity>> toggleUserStatus(String userId, String status);
  Future<Either<Failure, UserEntity>> toggleAdminStatus(String userId, bool currentlyIsAdmin);
  Future<Either<Failure, void>> deleteUser(String userId);
}


class PaginatedUserList {
  final List<UserEntity> users;
  final int totalCount;
  final int totalPages;
  final int page;
  final int limit;

  const PaginatedUserList({
    required this.users,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    required this.limit,
  });
}