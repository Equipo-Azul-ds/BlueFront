import 'dart:async';

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
  Timer? _tokenRefreshTimer;
  bool sessionExpiring = false;
  int sessionExpiryTick = 0; // aumenta cada vez que se debe mostrar el aviso
  static const Duration _tokenTtl = Duration(hours: 24);
  static const Duration _refreshLead = Duration(hours: 2);
  static const String _tokenIssuedAtKey = 'tokenIssuedAt';

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
    // Optimización: si no hay token, no intentamos nada.
    final token = await storage.read('token');
    if (token == null) {
      if (currentUser != null) {
        currentUser = null;
        notifyListeners(); // Solo notificar si cambió el estado
      }
      return;
    }

    await _run(() async {
      try {
        currentUser = await getCurrentUser();
        if (currentUser == null) return;

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
        await _scheduleTokenRefresh();
      } catch (e) {
        // Handle 401 specifically: clear session instead of throwing
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
           print('[auth] Session expired or invalid (401). clearing storage.');
           currentUser = null;
           await storage.deleteAll();
           return; 
        }
        rethrow;
      }
    });
  }

  // Login simplificado: busca por username/email y guarda token mock.
  Future<User?> login(String userOrEmail, String password) async {
    return _run<User?>(() async {
      // Llama al endpoint real de login y guarda el token para siguientes peticiones.
      // ignore: avoid_print
      print('[auth] login POST /auth/login username=$userOrEmail');
      final result = await repository.login(userOrEmail, password);
      final token = result['token'] as String;
      final user = result['user'] as User;
      if (token.isEmpty) {
        throw Exception('Token vacío en respuesta');
      }
      await storage.write('token', token);
      await storage.write('currentUserId', user.id);
      await _recordTokenIssuedAt();
      await _scheduleTokenRefresh();
      currentUser = user;

      // Imprimir el token y el userId en la terminal
      print('[auth] Token obtenido y guardado: $token');
      print('[auth] UserId obtenido y guardado: ${user.id}');

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
    String avatarUrl = '',
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
      User? createdUser;
      try {
        createdUser = await getUserByName(userName);
      } catch (_) {
        // Si el backend no permite leer sin autenticación, continuamos sin lanzar error.
        createdUser = null;
      }

      if (createdUser != null) {
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
              theme: createdUser.theme,
              language: createdUser.language,
              gameStreak: createdUser.gameStreak,
            ),
          );
        }
      }

      return currentUser;
    });
  }

  Future<void> updateProfile({String? name, String? description, String? avatarUrl, String? theme, String? language}) async {
    await _run(() async {
      if (currentUser == null) throw Exception('No session');
      final user = currentUser!;
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
      // Debug: imprime los campos que se enviarán
      // ignore: avoid_print
      print('[auth] updateProfile id=${user.id} sending fields=$fields');
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          final u = Uri.parse(avatarUrl);
          final seed = u.queryParameters['seed'];
          if (seed != null && seed.isNotEmpty) {
            fields['avatarAssetId'] = seed; // Use the seed as the ID
          } else if (!avatarUrl.contains('://')) {
            // If it doesn't look like a URL, assume it's already a valid ID
            fields['avatarAssetId'] = avatarUrl;
          }
        } catch (_) {
          // If it's not a valid URL, it might already be an ID
          if (!avatarUrl.contains('://')) fields['avatarAssetId'] = avatarUrl;
        }
      }

      currentUser = await updateSettings(
        UpdateUserSettingsParams(
          userName: fields['userName'],
          email: fields['email'],
          name: fields['name'],
          description: fields['description'],
          avatarUrl: fields['avatarUrl'],
          avatarAssetId: fields['avatarAssetId'],
          userType: fields['userType'],
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
      // Debug: imprime los campos que se enviarán
      // ignore: avoid_print
      print('[auth] changeUserType id=${user.id} userName=${user.userName} email=${user.email} newType=$newType');
      currentUser = await updateSettings(
        UpdateUserSettingsParams(
          userName: user.userName,
          email: user.email,
          name: user.name,
          description: user.description,
          avatarUrl: user.avatarUrl,
          userType: newType,
          theme: user.theme,
          language: user.language,
          gameStreak: user.gameStreak,
        ),
      );
      currentUser = user.copyWith(userType: newType, updatedAt: DateTime.now());
    });
  }

  Future<void> changePassword({required String currentPassword, required String newPassword, required String confirmNewPassword}) async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      currentUser = await updateSettings(
        UpdateUserSettingsParams(
          userName: user.userName,
          email: user.email,
          name: user.name,
          description: user.description,
          avatarUrl: user.avatarUrl,
          userType: user.userType,
          theme: user.theme,
          language: user.language,
          gameStreak: user.gameStreak,
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        ),
      );
      // No almacenamos hash local; el backend maneja el cambio.
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
      _tokenRefreshTimer?.cancel();
      sessionExpiring = false;
      sessionExpiryTick = 0;
      await storage.deleteAll();
    });
  }

  Future<void> deleteAccount() async {
    await _run(() async {
      final user = currentUser;
      if (user == null) throw Exception('No session');
      await repository.delete(user.id);
      currentUser = null;
      _tokenRefreshTimer?.cancel();
      sessionExpiring = false;
      sessionExpiryTick = 0;
      await storage.deleteAll();
    });
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _recordTokenIssuedAt([DateTime? at]) async {
    final ts = (at ?? DateTime.now()).toIso8601String();
    await storage.write(_tokenIssuedAtKey, ts);
  }

  Future<DateTime?> _readTokenIssuedAt() async {
    final raw = await storage.read(_tokenIssuedAtKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleTokenRefresh() async {
    _tokenRefreshTimer?.cancel();
    var issuedAt = await _readTokenIssuedAt();
    if (issuedAt == null) {
      issuedAt = DateTime.now();
      await _recordTokenIssuedAt(issuedAt);
    }
    final refreshAt = issuedAt.add(_tokenTtl - _refreshLead);
    final wait = refreshAt.difference(DateTime.now());
    if (wait.isNegative) {
      await _refreshTokenNow();
      return;
    }
    _tokenRefreshTimer = Timer(wait, () {
      _onSessionExpiring();
    });
  }

  void _onSessionExpiring() {
    sessionExpiring = true;
    sessionExpiryTick++;
    notifyListeners();
  }

  Future<bool> refreshSession() async {
    try {
      await _refreshTokenNow(manual: true);
      sessionExpiring = false;
      notifyListeners();
      return true;
    } catch (_) {
      sessionExpiring = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _refreshTokenNow({bool manual = false}) async {
    final token = await storage.read('token');
    if (token == null || token.isEmpty) return;
    try {
      final result = await repository.checkStatus();
      final newToken = (result['token'] ?? '').toString();
      final user = result['user'] as User;
      if (newToken.isNotEmpty) {
        await storage.write('token', newToken);
        await _recordTokenIssuedAt();
      }
      await storage.write('currentUserId', user.id);
      currentUser = user;
      sessionExpiring = false;
      await _scheduleTokenRefresh();
    } catch (e) {
      // ignore: avoid_print
      print('[auth] token refresh failed: $e');
      if (!manual) {
        sessionExpiring = true;
        sessionExpiryTick++;
        notifyListeners();
      }
    }
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
