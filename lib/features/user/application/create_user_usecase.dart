import '../domain/entities/Membership.dart';
import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';
import 'errors/user_conflict_error.dart';
import 'errors/user_not_found_error.dart';

class CreateUserParams {
  final String id;
  final String userName;
  final String email;
  final String hashedPassword;
  final String userType; // 'student' | 'teacher' | 'personal'
  final String avatarUrl;
  final String name;
  final String theme; // 'light' | 'dark'
  final String language; // 'es' | 'en'
  final int gameStreak;
  final Membership? membership;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CreateUserParams({
    required this.id,
    required this.userName,
    required this.email,
    required this.hashedPassword,
    required this.userType,
    required this.avatarUrl,
    this.name = '',
    this.theme = 'light',
    this.language = 'es',
    this.gameStreak = 0,
    this.membership,
    this.createdAt,
    this.updatedAt,
  });
}

class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<void> call(CreateUserParams params) async {
    final existingById = await repository.getOneById(params.id);
    if (existingById != null) {
      throw UserConflictError('User with this ID already exists');
    }

    final existingByUserName = await repository.getOneByName(params.userName);
    if (existingByUserName != null) {
      throw UserConflictError('User with this username already exists');
    }

    final now = DateTime.now();
    final membership = params.membership ?? Membership.free();
    final user = User(
      id: params.id,
      userName: params.userName,
      name: params.name,
      email: params.email,
      hashedPassword: params.hashedPassword,
      userType: params.userType,
      avatarUrl: params.avatarUrl,
      theme: params.theme,
      language: params.language,
      gameStreak: params.gameStreak,
      membership: membership,
      createdAt: params.createdAt ?? now,
      updatedAt: params.updatedAt ?? now,
    );

    await repository.create(user);
  }
}
