import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';

class UpdateUserSettingsParams {
  final String? id;
  final String? userName;
  final String? email;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? userType;
  final String? hashedPassword;
  final String? theme;
  final String? language;
  final int? gameStreak;

  const UpdateUserSettingsParams({
    this.id,
    this.userName,
    this.email,
    this.name,
    this.description,
    this.avatarUrl,
    this.userType,
    this.hashedPassword,
    this.theme,
    this.language,
    this.gameStreak,
  });
}

class UpdateUserSettingsUseCase {
  final UserRepository repository;
  UpdateUserSettingsUseCase(this.repository);

  Future<User> call(UpdateUserSettingsParams params) {
    return repository.updateSettings(
      id: params.id,
      userName: params.userName,
      email: params.email,
      name: params.name,
      description: params.description,
      avatarUrl: params.avatarUrl,
      userType: params.userType,
      hashedPassword: params.hashedPassword,
      theme: params.theme,
      language: params.language,
      gameStreak: params.gameStreak,
    );
  }
}
