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
  Future<void> create(User user) async {
    final uri = Uri.parse('$baseUrl/user');
    final res = await _post(uri, user.toJson());
    _ensureSuccess(res, allowed: {200, 201});
  }

  @override
  Future<void> edit(User user) async {
    final uri = Uri.parse('$baseUrl/user/${user.id}');
    final res = await _patch(uri, user.toJson());
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
    final id = await currentUserIdProvider();
    if (id == null || id.isEmpty) {
      throw Exception('No current user id available');
    }
    final uri = Uri.parse('$baseUrl/user/$id');
    final res = await _get(uri);
    _ensureSuccess(res);
    return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<User> updateSettings({
    String? name,
    String? avatarUrl,
    String? theme,
    String? language,
  }) async {
    final id = await currentUserIdProvider();
    if (id == null || id.isEmpty) {
      throw Exception('No current user id available');
    }
    final uri = Uri.parse('$baseUrl/user/$id');
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (theme != null) 'theme': theme,
      if (language != null) 'language': language,
    };
    final res = await _patch(uri, body);
    _ensureSuccess(res);
    return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
