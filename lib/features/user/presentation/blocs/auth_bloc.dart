import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';

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
      // Intentar recuperar el hash de contraseña desde el almacenamiento seguro
      final savedHash = await storage.read('hashedPassword');
      if (savedHash != null && savedHash.isNotEmpty) {
        currentUser = currentUser!.copyWith(hashedPassword: savedHash);
      }
      // Si aún no tenemos hash, intenta traerlo del backend directamente
      if (currentUser != null && currentUser!.hashedPassword.isEmpty) {
        try {
          final fetched = await repository.getOneById(currentUser!.id);
          if (fetched != null && fetched.hashedPassword.isNotEmpty) {
            currentUser = currentUser!.copyWith(hashedPassword: fetched.hashedPassword);
            await storage.write('hashedPassword', fetched.hashedPassword);
          }
        } catch (_) {}
      }
    });
  }

  // Login simplificado: busca por username/email y guarda token mock.
  Future<User?> login(String userOrEmail, String password) async {
    return _run<User?>(() async {
      // Debug de entrada
      // ignore: avoid_print
      print('[auth] login start input=$userOrEmail isEmail=${userOrEmail.contains('@')}');

      final isEmail = userOrEmail.contains('@');
      User? user;
      if (isEmail) {
        user = await repository.getOneByEmail(userOrEmail);
        // fallback: algunos backends permiten login por username en el mismo campo
        user ??= await repository.getOneByName(userOrEmail);
      } else {
        user = await repository.getOneByName(userOrEmail);
      }

      if (user == null) {
        // ignore: avoid_print
        print('[auth] login user not found for $userOrEmail');
        throw Exception('Usuario no encontrado');
      }

      // ignore: avoid_print
      print('[auth] login fetched id=${user.id} userName=${user.userName} email=${user.email} type=${user.userType}');

      final hpw = user.hashedPassword;
      if (hpw.isEmpty) {
        // ignore: avoid_print
        print('[auth] login empty hashedPassword for user=${user.userName} -> permitiendo acceso temporal (sin verificación)');
        currentUser = user;
        await storage.write('token', 'mock-token');
        await storage.write('currentUserId', user.id);
        return user;
      }

      // Debug mínimo (no imprime la contraseña). Deja este print temporal mientras validamos el backend.
      // ignore: avoid_print
      print('[auth] login user=${user.userName} hashLen=${hpw.length} prefix=${hpw.substring(0, hpw.length > 7 ? 7 : hpw.length)}');

      final looksBcrypt = hpw.startsWith(r'$2');
      // ignore: avoid_print
      print('[auth] login looksBcrypt=$looksBcrypt');
      final ok = looksBcrypt ? BCrypt.checkpw(password, hpw) : password == hpw;

      // ignore: avoid_print
      print('[auth] login passwordMatch=$ok');

      if (!ok) {
        throw Exception('Contraseña incorrecta');
      }

      currentUser = user;
      await storage.write('token', 'mock-token');
      await storage.write('currentUserId', user.id);
      if (hpw.isNotEmpty) {
        await storage.write('hashedPassword', hpw);
      }
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
      // Backend exige password en texto plano; no aplicar hash aquí.
      final plainPassword = password;
      // Usa exactamente el nombre que el usuario ingresó en el formulario (ya validado como no vacío)
      final safeName = name.trim();
      final safeAvatar = avatarUrl.trim().isEmpty
          ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D47A1&color=fff'
          : avatarUrl.trim();
      await createUser(
        CreateUserParams(
          id: id,
          userName: userName,
          email: email,
          hashedPassword: plainPassword,
          userType: userType,
          avatarUrl: safeAvatar,
          name: safeName,
        ),
      );
      // Luego busca al usuario recién creado (mock) para setear currentUser
      final createdUser = await getUserByName(userName);
      currentUser = createdUser;
      await storage.write('currentUserId', createdUser.id);
      await storage.write('hashedPassword', plainPassword);

      // Si por alguna razón el backend devolvió name vacío, fuerza un PATCH inmediato con name e invariantes.
      if (createdUser.name.trim().isEmpty && safeName.isNotEmpty) {
        // ignore: avoid_print
        print('[auth] signup detected empty name, patching with safeName="$safeName"');
        currentUser = await updateSettings(
          UpdateUserSettingsParams(
            userName: createdUser.userName,
            email: createdUser.email,
            name: safeName,
            description: createdUser.description,
            avatarUrl: createdUser.avatarUrl,
            userType: createdUser.userType,
            hashedPassword: plainPassword,
            theme: createdUser.theme,
            language: createdUser.language,
            gameStreak: createdUser.gameStreak,
          ),
        );
      }

      return currentUser;
    });
  }

  Future<void> updateProfile({String? name, String? description, String? avatarUrl, String? theme, String? language}) async {
    await _run(() async {
      if (currentUser == null) throw Exception('No session');
      // Garantiza que tengamos hashedPassword antes de enviar el PATCH
      if (currentUser!.hashedPassword.isEmpty) {
        try {
          final fetched = await repository.getOneById(currentUser!.id);
          if (fetched != null && fetched.hashedPassword.isNotEmpty) {
            currentUser = currentUser!.copyWith(hashedPassword: fetched.hashedPassword);
            await storage.write('hashedPassword', fetched.hashedPassword);
          }
        } catch (_) {}
      }
      final user = currentUser!;
      final hpw = user.hashedPassword;
      final fields = <String, dynamic>{
        'userName': user.userName,
        'email': user.email,
        'userType': user.userType,
        'avatarUrl': user.avatarUrl,
        'theme': user.theme,
        'language': user.language,
        'name': user.name,
        'description': user.description,
        'gameStreak': user.gameStreak,
      };
      if (name != null && name != user.name) fields['name'] = name;
      if (avatarUrl != null && avatarUrl != user.avatarUrl) fields['avatarUrl'] = avatarUrl;
      if (description != null && description != user.description && description.isNotEmpty) {
        fields['description'] = description;
      }
      if (theme != null && theme != user.theme) fields['theme'] = theme;
      if (language != null && language != user.language) fields['language'] = language;
      if (hpw.isNotEmpty) fields['hashedPassword'] = hpw;
      // Debug: imprime los campos que se enviarán
      // ignore: avoid_print
      print('[auth] updateProfile id=${user.id} sending fields=$fields');
      currentUser = await updateSettings(
        UpdateUserSettingsParams(
          userName: fields['userName'],
          email: fields['email'],
          name: fields['name'],
          description: fields['description'],
          avatarUrl: fields['avatarUrl'],
          userType: fields['userType'],
          hashedPassword: fields['hashedPassword'],
          theme: fields['theme'],
          language: fields['language'],
          gameStreak: fields['gameStreak'],
        ),
      );
    });
  }

  Future<void> changeUserType(String newType) async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      // Garantiza hash antes de enviar PATCH de tipo
      if (user.hashedPassword.isEmpty) {
        try {
          final fetched = await repository.getOneById(user.id);
          if (fetched != null && fetched.hashedPassword.isNotEmpty) {
            currentUser = user.copyWith(hashedPassword: fetched.hashedPassword);
            await storage.write('hashedPassword', fetched.hashedPassword);
          }
        } catch (_) {}
      }
      // Debug: imprime los campos que se enviarán
      // ignore: avoid_print
      print('[auth] changeUserType id=${user.id} userName=${user.userName} email=${user.email} newType=$newType hasHash=${user.hashedPassword.isNotEmpty}');
      final params = EditUserParams(
        id: user.id,
        userName: user.userName,
        email: user.email,
        userType: newType,
        avatarUrl: user.avatarUrl,
        name: user.name,
        description: user.description,
        theme: user.theme,
        language: user.language,
        gameStreak: user.gameStreak,
        hashedPassword: currentUser!.hashedPassword.isNotEmpty ? currentUser!.hashedPassword : null,
      );
      await editUser(params);
      currentUser = user.copyWith(userType: newType, updatedAt: DateTime.now());
    });
  }

  Future<void> changePassword(String newPassword) async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      final hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      final params = EditUserParams(
        id: user.id,
        userName: user.userName,
        email: user.email,
        userType: user.userType,
        avatarUrl: user.avatarUrl,
        name: user.name,
        description: user.description,
        theme: user.theme,
        language: user.language,
        gameStreak: user.gameStreak,
        hashedPassword: hashed,
            // password plano ya enviado al crear
      );
      await editUser(params);
      currentUser = user.copyWith(updatedAt: DateTime.now(), hashedPassword: hashed);
      await storage.write('hashedPassword', hashed);
    });
  }

  /// Cuando el backend exige `hashedPassword` en cualquier PATCH y la sesión no tiene hash,
  /// pedimos la contraseña al usuario y calculamos un hash bcrypt localmente.
  /// Esto NO cambia la contraseña en el backend por sí solo; sólo prepara el hash
  /// para ser incluido en futuras solicitudes de edición.
  Future<void> providePasswordForValidation(String password) async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      // Genera un hash bcrypt usable (formato $2b$...).
      final hashed = BCrypt.hashpw(password, BCrypt.gensalt());
      // ignore: avoid_print
      print('[auth] providePasswordForValidation set hashed (len=${hashed.length}) for user=${user.userName}');
      currentUser = user.copyWith(hashedPassword: hashed);
      await storage.write('hashedPassword', hashed);
    });
  }

  Future<void> logout() async {
    await _run(() async {
      currentUser = null;
      await storage.deleteAll();
    });
  }

  Future<void> deleteAccount() async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      await repository.delete(user.id);
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
