import 'package:Trivvy/features/Administrador/Aplication/dtos/userDTO.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';
import '../dtos/user_query_params.dart';

class GetUserListUseCase {
  final IUserRepository repository;

  GetUserListUseCase(this.repository);

  Future<Either<Failure, PaginatedUserList>> execute({
    required UserQueryParams params,
  }) async {
    return await repository.getUsers(params);
  }
}