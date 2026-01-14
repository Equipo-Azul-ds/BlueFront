import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/User.dart';
import '../../domain/repositories/UserRepository.dart';

/// Provides HTTP headers (e.g., Authorization) at call time.
typedef HeadersProvider = Future<Map<String, String>> Function();
/// Provides current user id when needed for self operations.
typedef CurrentUserIdProvider = Future<String?> Function();

class UserRepositoryImpl implements UserRepository {
  final String baseUrl;
  final http.Client client;
  final HeadersProvider headersProvider;
  final CurrentUserIdProvider currentUserIdProvider;

  UserRepositoryImpl({
    required this.baseUrl,
    required this.headersProvider,
    required this.currentUserIdProvider,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  Future<List<User>> getAll() async {
    final uri = Uri.parse('$baseUrl/user');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => User.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      throw Exception('Unexpected response parsing users list');
    }
    throw Exception('Failed to fetch users: ${res.statusCode} ${res.body}');
  }

  @override
  Future<User?> getOneById(String id) async {
    final uri = Uri.parse('$baseUrl/user/$id');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to fetch user: ${res.statusCode} ${res.body}');
  }

  @override
  Future<User?> getOneByName(String name) async {
    final uri = Uri.parse('$baseUrl/user/username/$name');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      // Debug: inspecciona respuesta cruda para verificar campos de contraseña.
      // ignore: avoid_print
      print('[user_repo] GET /user/username/$name -> ${res.body}');
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return User.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to fetch user by name: ${res.statusCode} ${res.body}');
  }

  @override
  Future<User?> getOneByEmail(String email) async {
    final uri = Uri.parse('$baseUrl/user/email/$email');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      // Debug: inspecciona respuesta cruda para verificar campos de contraseña.
      // ignore: avoid_print
      print('[user_repo] GET /user/email/$email -> ${res.body}');
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return User.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to fetch user by email: ${res.statusCode} ${res.body}');
  }

  @override
  Future<void> create(User user) async {
    final uri = Uri.parse('$baseUrl/user');
    if (user.hashedPassword.isEmpty) {
      throw Exception('password requerido para crear usuario');
    }

    // Normaliza según contrato del backend: password en claro, campos exactos y restricciones.
    final safeNameRaw = user.name.trim().isEmpty ? user.userName : user.name.trim();
    final safeName = safeNameRaw.length > 148 ? safeNameRaw.substring(0, 148) : safeNameRaw;
    final mappedType = user.userType.toUpperCase().contains('TEACH') ? 'TEACHER' : 'STUDENT';

    final body = <String, dynamic>{
      'email': user.email.trim(),
      'username': user.userName.trim(),
      'password': user.hashedPassword, // password plano según contrato
      'name': safeName,
      'type': mappedType,
    };

    // Debug: confirma payload enviado al registrar
    // ignore: avoid_print
    print('[user_repository] POST /user body=$body');

    final res = await _post(uri, body);
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[user_repository] POST /user -> ${res.statusCode} ${res.body}');
    }
    _ensureSuccess(res, allowed: {200, 201});
  }

  @override
  Future<void> edit(User user) async {
    final uri = Uri.parse('$baseUrl/user/${user.id}');
    final body = <String, dynamic>{
      'userName': user.userName,
      'email': user.email,
      'userType': user.userType,
      'avatarUrl': user.avatarUrl,
      'name': user.name,
      if (user.description.isNotEmpty) 'description': user.description,
      if (user.hashedPassword.isNotEmpty) 'hashedPassword': user.hashedPassword,
      if (user.hashedPassword.isNotEmpty) 'password': user.hashedPassword,
    };
    // Debug: imprime payload de PATCH
    // ignore: avoid_print
    print('[user_repo] PATCH $uri body=$body');
    final res = await _patch(uri, body);
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[user_repo] PATCH $uri -> ${res.statusCode} ${res.body}');
    }
    _ensureSuccess(res, allowed: {200, 204});
  }

  @override
  Future<void> partialEdit(String id, Map<String, dynamic> fields) async {
    final uri = Uri.parse('$baseUrl/user/$id');
    // Build minimal allowed body: only include present keys.
    final body = <String, dynamic>{};
    for (final entry in fields.entries) {
      final k = entry.key;
      var v = entry.value;
      if (v == null) continue;
      if (k == 'avatarUrl' && v is String) {
        final s = v as String;
        final startsHttp = s.startsWith('http://') || s.startsWith('https://');
        if (!startsHttp) {
          v = 'https://ui-avatars.com/api/?name=&background=0D47A1&color=fff';
        }
      }
      if (k == 'theme' && v is String) {
        final lower = (v as String).toLowerCase();
        v = lower.contains('dark') ? 'dark' : 'light';
      }
      if (k == 'language' && v is String) {
        final lower = (v as String).toLowerCase();
        v = lower.startsWith('en') ? 'en' : 'es';
      }
      if (k == 'userName' ||
          k == 'email' ||
          k == 'userType' ||
          k == 'avatarUrl' ||
          k == 'name' ||
          k == 'description' ||
          k == 'theme' ||
          k == 'language' ||
          k == 'gameStreak' ||
          k == 'hashedPassword' ||
          k == 'password') {
        body[k] = v;
      }
    }
    // Do NOT auto-mirror hashed -> password; only include what caller intends.
    // Debug: imprime payload de PATCH
    // ignore: avoid_print
    print('[user_repo] PATCH $uri body=$body');
    final res = await _patch(uri, body);
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[user_repo] PATCH $uri -> ${res.statusCode} ${res.body}');
    }
    _ensureSuccess(res, allowed: {200, 204});
  }

  @override
  Future<void> delete(String id) async {
    final uri = Uri.parse('$baseUrl/user/$id');
    final res = await _delete(uri);
    _ensureSuccess(res, allowed: {200, 204});
  }

  @override
  Future<User> getCurrentUser() async {
    // Usa el endpoint de perfil autenticado y el token en headersProvider
    final uri = Uri.parse('$baseUrl/user/profile/');
    final res = await _get(uri);
    _ensureSuccess(res, allowed: {200});
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  @override
  Future<User> updateSettings({
    String? userName,
    String? email,
    String? name,
    String? description,
    String? avatarUrl,
    String? userType,
    String? theme,
    String? language,
    int? gameStreak,
    String? currentPassword,
    String? newPassword,
    String? confirmNewPassword,
  }) async {
    // PATCH del perfil autenticado usando token: /user/profile/
    final uri = Uri.parse('$baseUrl/user/profile/');

    // Mapear a nombres exactos del contrato
    final String? mappedUsername = userName;
    final String? mappedEmail = email;
    final String? mappedName = name;
    final String? mappedDescription = description;
    // Backend espera 'avatarAssetId' (no URL). Intentamos extraer un id válido.
    String? mappedAvatarId;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final u = Uri.parse(avatarUrl);
        final seed = u.queryParameters['seed'];
        if (seed != null && seed.isNotEmpty) {
          mappedAvatarId = seed; // usa el seed como id
        } else if (!avatarUrl.contains('://')) {
          // Si no parece URL, asumimos que es un id ya válido
          mappedAvatarId = avatarUrl;
        }
      } catch (_) {
        // Si no es una URL válida, podría ser directamente un id
        if (!avatarUrl.contains('://')) mappedAvatarId = avatarUrl;
      }
    }
    final String? mappedThemePref = theme != null
        ? (theme.toUpperCase() == 'DARK' ? 'DARK' : 'LIGHT')
        : null;
    // Mapear tipo si se envía (student/teacher -> STUDENT/TEACHER)
    final String? mappedType = userType != null
        ? (userType.toUpperCase().contains('TEACH') ? 'TEACHER' : 'STUDENT')
        : null;

    final payload = <String, dynamic>{
      if (mappedUsername != null) 'username': mappedUsername,
      if (mappedEmail != null) 'email': mappedEmail,
      if (mappedName != null) 'name': mappedName,
      if (mappedDescription != null) 'description': mappedDescription,
      if (mappedAvatarId != null) 'avatarAssetId': mappedAvatarId,
      if (mappedThemePref != null) 'themePreference': mappedThemePref,
      if (mappedType != null) 'type': mappedType,
      if (currentPassword != null) 'currentPassword': currentPassword,
      if (newPassword != null) 'newPassword': newPassword,
      if (confirmNewPassword != null) 'confirmNewPassword': confirmNewPassword,
    };

    // Debug: imprime payload y URL
    // ignore: avoid_print
    print('[user_repo] PATCH $uri body=$payload');

    final res = await _patch(uri, payload);
    // ignore: avoid_print
    print('[user_repo] PATCH $uri -> ${res.statusCode} ${res.body}');
    _ensureSuccess(res, allowed: {200});

    // Respuesta con objeto user anidado
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  @override
  Future<User> setMembershipPremium(bool enabled) async {
    final id = await currentUserIdProvider();
    if (id == null || id.isEmpty) {
      throw Exception('No current user id available');
    }
    if (enabled) {
      final uri = Uri.parse('$baseUrl/user/$id/subscription');
      final res = await _post(uri, const {});
      _ensureSuccess(res, allowed: {200, 201});
      // After change, fetch subscription status or user; backend returns void, so fetch user
      return (await getOneById(id))!;
    } else {
      final uri = Uri.parse('$baseUrl/user/$id/subscription');
      final res = await _delete(uri);
      _ensureSuccess(res, allowed: {200, 204});
      return (await getOneById(id))!;
    }
  }

  Future<http.Response> _get(Uri uri) async {
    final headers = await headersProvider();
    return client.get(uri, headers: headers);
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    return client.post(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // Login de auth: no requiere Authorization y retorna token + usuario
  Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );
    _ensureSuccess(res, allowed: {200, 201});
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    final userJson = data['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data)
        : data; // User.fromJson soporta anidado
    final user = User.fromJson(userJson);
    return {'token': token, 'user': user};
  }

  Future<http.Response> _put(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    return client.put(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    return client.patch(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _delete(Uri uri) async {
    final headers = await headersProvider();
    return client.delete(uri, headers: headers);
  }

  void _ensureSuccess(http.Response res, {Set<int> allowed = const {200}}) {
    if (!allowed.contains(res.statusCode)) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
