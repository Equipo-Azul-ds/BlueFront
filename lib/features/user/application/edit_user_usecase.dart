import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';
import 'errors/user_conflict_error.dart';
import 'errors/user_not_found_error.dart';

class EditUserParams {
  final String id;
  final String userName;
  final String email;
  final String userType; // 'student' | 'teacher' | 'personal'
  final String avatarUrl;
  final String name;
  final String theme;
  final String language;
  final int gameStreak;

  const EditUserParams({
    required this.id,
    required this.userName,
    required this.email,
    required this.userType,
    required this.avatarUrl,
    required this.name,
    required this.theme,
    required this.language,
    required this.gameStreak,
  });
}

class EditUserUseCase {
  final UserRepository repository;

  EditUserUseCase(this.repository);

  Future<void> call(EditUserParams params) async {
    final existing = await repository.getOneById(params.id);
    if (existing == null) {
      throw UserNotFoundError();
    }

    final existingByName = await repository.getOneByName(params.userName);
    if (existingByName != null && existingByName.id != params.id) {
      throw UserConflictError('That username belongs to another user');
    }

    final updated = User(
      id: params.id,
      userName: params.userName,
      name: params.name,
      email: params.email,
      userType: params.userType,
      avatarUrl: params.avatarUrl,
      theme: params.theme,
      language: params.language,
      gameStreak: params.gameStreak,
      membership: existing.membership,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await repository.edit(updated);
  }
}
