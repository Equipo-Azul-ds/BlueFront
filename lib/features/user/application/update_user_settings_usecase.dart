import '../domain/entities/User.dart';
import '../domain/repositories/UserRepository.dart';

class UpdateUserSettingsParams {
  final String? name;
  final String? avatarUrl;
  final String? theme;
  final String? language;

  const UpdateUserSettingsParams({
    this.name,
    this.avatarUrl,
    this.theme,
    this.language,
  });
}

class UpdateUserSettingsUseCase {
  final UserRepository repository;
  UpdateUserSettingsUseCase(this.repository);

  Future<User> call(UpdateUserSettingsParams params) {
    return repository.updateSettings(
      name: params.name,
      avatarUrl: params.avatarUrl,
      theme: params.theme,
      language: params.language,
    );
  }
}
