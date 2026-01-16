import '../domain/repositories/UserRepository.dart';

class DeleteUserUseCase {
  final UserRepository repository;

  DeleteUserUseCase(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}
