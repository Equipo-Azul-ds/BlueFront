import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';
import 'errors/user_not_found_error.dart';

class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  Future<User> call(String id) async {
    final user = await repository.getOneById(id);
    if (user == null) {
      throw UserNotFoundError();
    }
    return user;
  }
}
