import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';

class GetAllUsersUseCase {
  final UserRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<User>> call() {
    return repository.getAll();
  }
}
