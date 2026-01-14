import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';

class UpdateUserSettingsParams {
  final String? userName;
  final String? email;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? userType;
  final String? theme;
  final String? language;
  final int? gameStreak;
  // Campos específicos para cambio de contraseña según contrato PATCH /user/profile/
  final String? currentPassword;
  final String? newPassword;
  final String? confirmNewPassword;

  const UpdateUserSettingsParams({
    this.userName,
    this.email,
    this.name,
    this.description,
    this.avatarUrl,
    this.userType,
    this.theme,
    this.language,
    this.gameStreak,
    this.currentPassword,
    this.newPassword,
    this.confirmNewPassword,
  });
}

class UpdateUserSettingsUseCase {
  final UserRepository repository;
  UpdateUserSettingsUseCase(this.repository);

  Future<User> call(UpdateUserSettingsParams params) {
    return repository.updateSettings(
      userName: params.userName,
      email: params.email,
      name: params.name,
      description: params.description,
      avatarUrl: params.avatarUrl,
      userType: params.userType,
      theme: params.theme,
      language: params.language,
      gameStreak: params.gameStreak,
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
      confirmNewPassword: params.confirmNewPassword,
    );
  }
}
