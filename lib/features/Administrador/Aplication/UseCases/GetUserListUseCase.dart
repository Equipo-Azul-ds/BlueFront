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
    // Aquí se podría añadir lógica de validación de negocio antes de llamar al repositorio
    // (ej: si el usuario actual es realmente un administrador)

    return repository.getUsers(params);
  }
}