import '../domain/repositories/UserRepository.dart';
import 'errors/user_not_found_error.dart';

class EnablePremiumMembershipUseCase {
  final UserRepository repository;

  EnablePremiumMembershipUseCase(this.repository);

  Future<void> call(String id) async {
    final user = await repository.getOneById(id);
    if (user == null) {
      throw UserNotFoundError();
    }

    final updated = user.enablePremiumMembership();
    await repository.edit(updated);
  }
}
