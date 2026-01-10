import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';
import '../../Dominio/entidad/User.dart';

class ToggleAdminRoleUseCase {
  final IUserRepository repository;
  ToggleAdminRoleUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String userId, bool currentlyIsAdmin) {
    return repository.toggleAdminStatus(userId, currentlyIsAdmin);
  }
}