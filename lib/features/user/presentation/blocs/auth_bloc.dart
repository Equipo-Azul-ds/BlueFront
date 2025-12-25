import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../application/create_user_usecase.dart';
import '../../application/edit_user_usecase.dart';
import '../../application/get_current_user_usecase.dart';
import '../../application/get_user_by_name_usecase.dart';
import '../../application/update_user_settings_usecase.dart';
import '../../domain/entities/User.dart';
import '../../domain/repositories/UserRepository.dart';
import '../../../../local/secure_storage.dart';

/// Auth / Perfil bloc ligero basado en ChangeNotifier.
/// Este bloc es mock-friendly: si no hay endpoints de auth, hace fetch por username
/// y almacena un token de demostración en secure storage.
class AuthBloc extends ChangeNotifier {
  final UserRepository repository;
  final CreateUserUseCase createUser;
  final EditUserUseCase editUser;
  final GetCurrentUserUseCase getCurrentUser;
  final GetUserByNameUseCase getUserByName;
  final UpdateUserSettingsUseCase updateSettings;
  final SecureStorage storage;

  User? currentUser;
  bool isLoading = false;
  String? error;

  AuthBloc({
    required this.repository,
    required this.createUser,
    required this.editUser,
    required this.getCurrentUser,
    required this.getUserByName,
    required this.updateSettings,
    SecureStorage? storage,
  }) : storage = storage ?? SecureStorage.instance;

  // Carga usuario actual si hay sesión.
  Future<void> loadSession() async {
    await _run(() async {
      currentUser = await getCurrentUser();
    });
  }

  // Login simplificado: busca por username/email y guarda token mock.
  Future<User?> login(String userOrEmail, String password) async {
    return _run<User?>(() async {
      // TODO: reemplazar por endpoint real de auth; esto solo busca por nombre.
      final user = await getUserByName(userOrEmail);
      currentUser = user;
      await storage.write('token', 'mock-token');
      await storage.write('currentUserId', user.id);
      return user;
    });
  }

  // Reset de contraseña simplificado: sólo mockea el envío de correo.
  Future<void> resetPassword(String email) async {
    await _run(() async {
      // TODO: reemplazar por endpoint real de reset password
      await Future.delayed(const Duration(milliseconds: 500));
    });
  }

  // Registro usando CreateUserUseCase. Genera UUID si no llega id.
  Future<User?> signup({
    required String userName,
    required String email,
    required String password,
    required String userType,
    required String avatarUrl,
    String name = '',
  }) async {
    return _run<User?>(() async {
      final id = const Uuid().v4();
      await createUser(
        CreateUserParams(
          id: id,
          userName: userName,
          email: email,
          userType: userType,
          avatarUrl: avatarUrl,
          name: name,
        ),
      );
      // Luego busca al usuario recién creado (mock) para setear currentUser
      final createdUser = await getUserByName(userName);
      currentUser = createdUser;
      await storage.write('currentUserId', createdUser.id);
      return currentUser;
    });
  }

  Future<void> updateProfile({String? name, String? avatarUrl, String? theme, String? language}) async {
    await _run(() async {
      if (currentUser == null) throw Exception('No session');
      currentUser = await updateSettings(
        UpdateUserSettingsParams(
          name: name,
          avatarUrl: avatarUrl,
          theme: theme,
          language: language,
        ),
      );
    });
  }

  Future<void> changeUserType(String newType) async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      final params = EditUserParams(
        id: user.id,
        userName: user.userName,
        email: user.email,
        userType: newType,
        avatarUrl: user.avatarUrl,
        name: user.name,
        theme: user.theme,
        language: user.language,
        gameStreak: user.gameStreak,
      );
      await editUser(params);
      currentUser = user.copyWith(userType: newType, updatedAt: DateTime.now());
    });
  }

  Future<void> logout() async {
    await _run(() async {
      currentUser = null;
      await storage.deleteAll();
    });
  }

  Future<T> _run<T>(Future<T> Function() op) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      return await op();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
