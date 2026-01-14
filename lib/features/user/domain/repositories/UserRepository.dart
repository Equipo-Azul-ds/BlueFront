import '../entities/User.dart';

abstract class UserRepository {
  Future<List<User>> getAll();

  Future<User?> getOneById(String id);

  Future<User?> getOneByName(String name);

  Future<User?> getOneByEmail(String email);

  Future<void> create(User user);

  Future<void> edit(User user);

  /// Partially update user by ID with only the provided fields.
  /// Payload should include only changed keys to avoid backend validation issues.
  Future<void> partialEdit(String id, Map<String, dynamic> fields);

  Future<void> delete(String id);

  Future<User> getCurrentUser();

  Future<User> updateSettings({
    String? id,
    String? userName,
    String? email,
    String? name,
    String? description,
    String? avatarUrl,
    String? userType,
    String? hashedPassword,
    String? theme, // 'light' | 'dark'
    String? language, // 'es' | 'en' | ...
    int? gameStreak,
  });

  Future<User> setMembershipPremium(bool enabled);

  /// Auth login: POST /auth/login returns token + user
  /// Returns a map with keys 'token' (String) and 'user' (User)
  Future<Map<String, dynamic>> login(String username, String password);
}