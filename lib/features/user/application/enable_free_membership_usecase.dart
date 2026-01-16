import '../domain/repositories/UserRepository.dart';
import 'errors/user_not_found_error.dart';

class EnableFreeMembershipUseCase {
  final UserRepository repository;

  EnableFreeMembershipUseCase(this.repository);

  Future<void> call(String id) async {
    final user = await repository.getOneById(id);
    if (user == null) {
      throw UserNotFoundError();
    }

    final updated = user.enableFreeMembership();
    await repository.edit(updated);
  }
}
