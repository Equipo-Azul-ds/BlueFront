import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';
import 'errors/user_not_found_error.dart';

class GetUserByNameUseCase {
  final UserRepository repository;

  GetUserByNameUseCase(this.repository);

  Future<User> call(String userName) async {
    final user = await repository.getOneByName(userName);
    if (user == null) {
      throw UserNotFoundError();
    }
    return user;
  }
}
