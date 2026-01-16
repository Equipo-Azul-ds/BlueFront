import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';


class DeleteUserUseCase {
  final IUserRepository repository;
  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> execute(String userId) {
    return repository.deleteUser(userId);
  }
}