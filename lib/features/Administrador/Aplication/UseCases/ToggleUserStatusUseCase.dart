import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../Dominio/Repositorio/IUserManagementRepository.dart';
import '../../Dominio/entidad/User.dart';


class ToggleUserStatusUseCase {
  final IUserRepository repository;
  ToggleUserStatusUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String userId, String currentStatus) {
    final newStatus = currentStatus == 'active' ? 'blocked' : 'active';
    return repository.toggleUserStatus(userId, newStatus);
  }
}