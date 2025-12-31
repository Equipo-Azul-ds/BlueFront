import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/Group.dart';
import '../../domain/entities/GroupInvitationToken.dart';
import '../../domain/entities/GroupMember.dart';
import '../../domain/entities/GroupQuizAssignment.dart';
import '../../domain/repositories/GroupRepository.dart';

/// Provides HTTP headers (Authorization, etc.) at call time.
typedef HeadersProvider = Future<Map<String, String>> Function();

/// Implementación thin: delega reglas al backend (controller NestJS).
class GroupRepositoryImpl implements GroupRepository {
  final String baseUrl;
  final http.Client client;
  final HeadersProvider headersProvider;

  GroupRepositoryImpl({
    required this.baseUrl,
    required this.headersProvider,
    http.Client? client,
  }) : client = client ?? http.Client();

  // --- Métodos del contrato (compat) ---------------------------------

  @override
  Future<Group?> findById(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    final res = await _get(uri);
    if (res.statusCode == 404) return null;
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  @override
  Future<List<Group>> findByMember(String userId) async {
    // El backend toma el usuario del token; userId se ignora.
    final uri = Uri.parse('$baseUrl/groups');
    final res = await _get(uri);
    _ensureSuccess(res, {200});
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Group.fromJson).toList();
    }
    throw Exception('Unexpected response for groups list');
  }

  @override
  Future<Group?> findByInvitationToken(String token) async {
    // El controller no expone lookup por token; se usa /groups/join.
    throw UnsupportedError('Backend no expone GET por token; usa joinByInvitation');
  }

  @override
  Future<void> save(Group group) async {
    // El controller expone endpoints específicos (create, patch, transfer, etc.).
    throw UnsupportedError('Usa endpoints dedicados: createGroup/updateGroupInfo/etc.');
  }

  // --- Endpoints del controller (Thin API) -----------------------------

  Future<Group> createGroup({required String name}) async {
    final uri = Uri.parse('$baseUrl/groups');
    final res = await _post(uri, {'name': name});
    _ensureSuccess(res, {201});
    return Group.fromJson(_asMap(res.body));
  }

  Future<Group> getGroupDetail(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    final res = await _get(uri);
    if (res.statusCode == 404) {
      throw Exception('Group $groupId not found');
    }
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/members');
    final res = await _get(uri);
    _ensureSuccess(res, {200});
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      final members = data['members'];
      if (members is List) {
        return members
            .whereType<Map<String, dynamic>>()
            .map(GroupMember.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response for group members');
  }

  Future<GroupInvitationToken> generateInvitation(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/invitation');
    final res = await _post(uri, {});
    _ensureSuccess(res, {200});
    final data = _asMap(res.body);
    return GroupInvitationToken(
      token: data['link']?.toString().split('/').last ?? '',
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<String> joinByInvitation(String token) async {
    final uri = Uri.parse('$baseUrl/groups/join');
    final res = await _post(uri, {'token': token});
    _ensureSuccess(res, {200});
    final data = _asMap(res.body);
    return data['groupId'] as String? ?? '';
  }

  Future<void> leaveGroup(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/leave');
    final res = await _post(uri, {});
    _ensureSuccess(res, {200});
  }

  Future<void> removeMember({required String groupId, required String memberId}) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/members/$memberId');
    final res = await _delete(uri);
    _ensureSuccess(res, {200});
  }

  Future<Group> updateGroupInfo({required String groupId, String? name, String? description}) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
    final res = await _patch(uri, payload);
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  Future<void> transferAdmin({required String groupId, required String newAdminUserId}) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/transfer-admin');
    final res = await _post(uri, {'newAdminUserId': newAdminUserId});
    _ensureSuccess(res, {200});
  }

  Future<GroupQuizAssignment> assignQuizToGroup({
    required String groupId,
    required String quizId,
    required DateTime availableUntil,
  }) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/quizzes');
    final res = await _post(uri, {
      'quizId': quizId,
      'availableUntil': availableUntil.toIso8601String(),
    });
    _ensureSuccess(res, {201});
    return GroupQuizAssignment.fromJson(_asMap(res.body));
  }

  // --- HTTP helpers ---------------------------------------------------

  Future<http.Response> _get(Uri uri) async {
    final headers = await headersProvider();
    return client.get(uri, headers: headers);
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    return client.post(uri,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body));
  }

  Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    return client.patch(uri,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body));
  }

  Future<http.Response> _delete(Uri uri) async {
    final headers = await headersProvider();
    return client.delete(uri, headers: headers);
  }

  void _ensureSuccess(http.Response res, Set<int> allowed) {
    if (!allowed.contains(res.statusCode)) {
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    }
  }

  Map<String, dynamic> _asMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response shape');
  }
}
