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
  final String _base;

  GroupRepositoryImpl({
    required this.baseUrl,
    required this.headersProvider,
    http.Client? client,
  })  : client = client ?? http.Client(),
        _base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  // --- Métodos del contrato (compat) ---------------------------------

  @override
  Future<Group?> findById(String groupId) async {
    final uri = Uri.parse('$_base/groups/$groupId');
    final res = await _get(uri);
    if (res.statusCode == 404) return null;
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  @override
  Future<List<Group>> findByMember(String userId) async {
    // El backend toma el usuario del token; userId se ignora.
    final uri = Uri.parse('$_base/groups');
    final res = await _get(uri);
    _ensureSuccess(res, {200});
    final decoded = jsonDecode(res.body);
    // Aceptar múltiples formas: List<Map>, {groups: List}, {data: List}, etc.
    List<Map<String, dynamic>>? list;
    if (decoded is List) {
      list = decoded.whereType<Map<String, dynamic>>().toList();
    } else if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['groups'], decoded['data'], decoded['items'], decoded['content'], decoded['result']
      ];
      list = candidates.firstWhere(
        (v) => v is List && (v as List).isNotEmpty && (v as List).first is Map,
        orElse: () => null,
      )?.whereType<Map<String, dynamic>>().toList();
      // Si no encontramos clave directa, intenta buscar la primera lista de mapas dentro del objeto.
      list ??= decoded.values
          .whereType<List>()
          .firstWhere(
            (v) => v.isNotEmpty && v.first is Map,
            orElse: () => <dynamic>[],
          )
          .whereType<Map<String, dynamic>>()
          .toList();
      if (list.isEmpty) {
        // Último recurso: si el backend devuelve un objeto único de grupo
        if (decoded.containsKey('id') && decoded['id'] is String) {
          return [Group.fromJson(decoded)];
        }
      }
    }
    if (list != null) {
      // lista vacía es válida: sin grupos creados.
      return list.map(Group.fromJson).toList();
    }
    // Si no hay lista pero la respuesta es un objeto con clave groups vacía, devolver []
    if (decoded is Map<String, dynamic> && decoded.containsKey('groups')) {
      final g = decoded['groups'];
      if (g is List) return g.whereType<Map<String, dynamic>>().map(Group.fromJson).toList();
      return <Group>[];
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
    final uri = Uri.parse('$_base/groups');
    try {
      // ignore: avoid_print
      print('[groups] createGroup POST ${uri.toString()} name="$name"');
    } catch (_) {}
    final res = await _post(uri, {'name': name});
    _ensureSuccess(res, {201});
    try {
      // ignore: avoid_print
      print('[groups] createGroup status=${res.statusCode} body=${res.body}');
    } catch (_) {}
    return Group.fromJson(_asMap(res.body));
  }

  Future<Group> getGroupDetail(String groupId) async {
    final uri = Uri.parse('$_base/groups/$groupId');
    final res = await _get(uri);
    if (res.statusCode == 404) {
      throw Exception('Group $groupId not found');
    }
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final uri = Uri.parse('$_base/groups/$groupId/members');
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
    final uri = Uri.parse('$_base/groups/$groupId/invitation');
    final res = await _post(uri, {});
    _ensureSuccess(res, {200, 201});
    final data = _asMap(res.body);
    final rawLink = data['link'] ?? data['Link'] ?? '';
    final parsedLink = rawLink is String ? rawLink : rawLink.toString();
    return GroupInvitationToken(
      token: parsedLink.isNotEmpty ? parsedLink.split('/').last : (data['token']?.toString() ?? ''),
      link: parsedLink,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<String> joinByInvitation(String token) async {
    final uri = Uri.parse('$_base/groups/join');
    final res = await _post(uri, {'token': token});
    _ensureSuccess(res, {200});
    final data = _asMap(res.body);
    return data['groupId'] as String? ?? '';
  }

  Future<void> leaveGroup(String groupId) async {
    final uri = Uri.parse('$_base/groups/$groupId/leave');
    final res = await _post(uri, {});
    try {
      // ignore: avoid_print
      print('[groups] leaveGroup <- status=${res.statusCode} body=${res.body}');
    } catch (_) {}
    _ensureSuccess(res, {200});
  }

  Future<void> removeMember({required String groupId, required String memberId}) async {
    final uri = Uri.parse('$_base/groups/$groupId/members/$memberId');
    final res = await _delete(uri);
    _ensureSuccess(res, {200});
  }

  Future<Group> updateGroupInfo({required String groupId, String? name, String? description}) async {
    final uri = Uri.parse('$_base/groups/$groupId');
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
    
    try {
      // ignore: avoid_print
      print('[groups] updateGroupInfo PATCH ${uri.toString()} body=$payload');
    } catch (_) {}

    final res = await _patch(uri, payload);
    
    // Si falla, _ensureSuccess lanzará la excepción, la cual puede ser atrapada por el Bloc
    _ensureSuccess(res, {200});
    return Group.fromJson(_asMap(res.body));
  }

  Future<void> transferAdmin({required String groupId, required String newAdminUserId}) async {
    final uri = Uri.parse('$_base/groups/$groupId/transfer-admin');
    final res = await _post(uri, {'newAdminUserId': newAdminUserId});
    _ensureSuccess(res, {200});
  }

  Future<GroupQuizAssignment> assignQuizToGroup({
    required String groupId,
    required String quizId,
    required DateTime availableUntil,
  }) async {
    final uri = Uri.parse('$_base/groups/$groupId/quizzes');
    final res = await _post(uri, {
      'quizId': quizId,
      'availableUntil': availableUntil.toIso8601String(),
    });
    try {
      // ignore: avoid_print
      print('[groups] assignQuizToGroup <- status=${res.statusCode} body=${res.body}');
    } catch (_) {}
    _ensureSuccess(res, {201});
    return GroupQuizAssignment.fromJson(_asMap(res.body));
  }

  Future<List<GroupQuizAssignment>> getGroupAssignments(String groupId) async {
    final uri = Uri.parse('$_base/groups/$groupId/quizzes');
    final res = await _get(uri);
    try {
      // ignore: avoid_print
      print('[groups] getGroupAssignments <- status=${res.statusCode}');
      print('[groups] getGroupAssignments <- body=${res.body}');
    } catch (_) {}
    _ensureSuccess(res, {200});
    final decoded = jsonDecode(res.body);
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // soportar {items: []}, {data: []}, {quizzes: []}, etc.
      list = (decoded['items'] ?? decoded['data'] ?? decoded['quizzes'] ?? decoded['assignments'] ?? decoded['quizAssignments'] ?? decoded['groupQuizzes']) as List? ?? [];
    } else {
      list = [];
    }
    final parsed = list
        .whereType<Map<String, dynamic>>()
        .map(GroupQuizAssignment.fromJson)
        .toList();
    try {
      // ignore: avoid_print
      print('[groups] getGroupAssignments -> parsed ${parsed.length} assignments');
    } catch (_) {}
    return parsed;
  }

  // --- HTTP helpers ---------------------------------------------------

  Future<http.Response> _get(Uri uri) async {
    final headers = await headersProvider();
    try {
      // ignore: avoid_print
      print('[groups] GET ${uri.toString()} headers=$headers');
    } catch (_) {}
    return client.get(uri, headers: headers);
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...headers,
    };
    try {
      // ignore: avoid_print
      print('[groups] POST ${uri.toString()} headers=$mergedHeaders body=$body');
    } catch (_) {}
    return client.post(uri,
        headers: mergedHeaders,
        body: jsonEncode(body));
  }

  Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) async {
    final headers = await headersProvider();
    try {
      // ignore: avoid_print
      print('[groups] PATCH ${uri.toString()} headers=$headers body=$body');
    } catch (_) {}
    return client.patch(uri,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body));
  }

  Future<http.Response> _delete(Uri uri) async {
    final headers = await headersProvider();
    try {
      // ignore: avoid_print
      print('[groups] DELETE ${uri.toString()} headers=$headers');
    } catch (_) {}
    return client.delete(uri, headers: headers);
  }

  void _ensureSuccess(http.Response res, Set<int> allowed) {
    if (!allowed.contains(res.statusCode)) {
      try {
        // ignore: avoid_print
        print('[groups] ERROR status=${res.statusCode} body=${res.body}');
      } catch (_) {}
      
      String msg = 'Request failed: ${res.statusCode}';
      if (res.statusCode == 400) msg = 'Datos inválidos (400)';
      if (res.statusCode == 401) msg = 'No autorizado (401)';
      if (res.statusCode == 403) msg = 'Sin permisos (403)';
      if (res.statusCode == 404) msg = 'No encontrado (404)';
      
      throw Exception('$msg - ${res.body}');
    }
  }

  Map<String, dynamic> _asMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response shape');
  }
}
