import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';

class GetCurrentUserUseCase {
  final UserRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<User> call() => repository.getCurrentUser();
}
