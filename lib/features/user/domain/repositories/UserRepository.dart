import '../entities/User.dart';

abstract class UserRepository {
  Future<List<User>> getAll();

  Future<User?> getOneById(String id);

  Future<User?> getOneByName(String name);

  Future<void> create(User user);

  Future<void> edit(User user);

  Future<void> delete(String id);

  Future<User> getCurrentUser();

  Future<User> updateSettings({
    String? name,
    String? avatarUrl,
    String? theme, // 'light' | 'dark'
    String? language, // 'es' | 'en' | ...
  });

  Future<User> setMembershipPremium(bool enabled);
}