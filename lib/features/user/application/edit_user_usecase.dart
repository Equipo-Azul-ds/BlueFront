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
  final String description;
  final String theme;
  final String language;
  final int gameStreak;
  final String? hashedPassword;

  const EditUserParams({
    required this.id,
    required this.userName,
    required this.email,
    required this.userType,
    required this.avatarUrl,
    required this.name,
    this.description = '',
    required this.theme,
    required this.language,
    required this.gameStreak,
    this.hashedPassword,
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

    // Compute minimal diff payload, but include invariants backend expects.
    final Map<String, dynamic> diff = {
      'userName': existing.userName,
      'email': existing.email,
      'userType': existing.userType,
      'avatarUrl': existing.avatarUrl,
      'theme': existing.theme,
      'language': existing.language,
      'name': existing.name,
      'description': existing.description,
      'gameStreak': existing.gameStreak,
    };
    if (params.userName != existing.userName) diff['userName'] = params.userName;
    if (params.email != existing.email) diff['email'] = params.email;
    if (params.userType != existing.userType) diff['userType'] = params.userType;
    if (params.avatarUrl != existing.avatarUrl) diff['avatarUrl'] = params.avatarUrl;
    if (params.name != existing.name) diff['name'] = params.name;
    if (params.description != existing.description) diff['description'] = params.description;
    if (params.theme != existing.theme) diff['theme'] = params.theme;
    if (params.language != existing.language) diff['language'] = params.language;
    if (params.gameStreak != existing.gameStreak) diff['gameStreak'] = params.gameStreak;
    // Password hash explicitly provided (e.g., changePassword)
    if (params.hashedPassword != null && params.hashedPassword!.isNotEmpty) {
      diff['hashedPassword'] = params.hashedPassword;
    }

    if (diff.isEmpty) {
      // Nothing to update
      return;
    }
    await repository.partialEdit(params.id, diff);
  }
}
