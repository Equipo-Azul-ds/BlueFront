import 'package:flutter/foundation.dart';

import '../../domain/entities/Group.dart';
import '../../domain/entities/GroupMember.dart';
import '../../domain/entities/GroupInvitationToken.dart';
import '../../domain/entities/GroupQuizAssignment.dart';
import '../../domain/repositories/GroupRepository.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';

class GroupsBloc extends ChangeNotifier {
  final GroupRepository repository;
  final AuthBloc auth;

  GroupsBloc({required this.repository, required this.auth});

  bool _loading = false;
  String? _error;
  List<Group> _groups = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Group> get groups => _groups;

  String? get _currentUserId => auth.currentUser?.id;

  Future<void> loadMyGroups() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      _error = 'Debes iniciar sesión para ver tus grupos';
      notifyListeners();
      return;
    }
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await repository.findByMember(userId);
      if (_groups.isEmpty) {
        _error = null; // lista vacía es válida
      }
    } catch (e) {
      _error = 'No se pudieron cargar tus grupos. Intenta nuevamente.';
      if (kDebugMode) {
        // Ayuda a depurar en desarrollo sin exponer el error crudo en UI.
        debugPrint('GroupsBloc.loadMyGroups error: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Group?> refreshGroup(String groupId) async {
    try {
      final grp = await repository.getGroupDetail(groupId);
      _groups = _groups.map((g) => g.id == groupId ? grp : g).toList();
      notifyListeners();
      return grp;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> createGroup(String name) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _error = 'Debes iniciar sesión para crear un grupo';
      notifyListeners();
      return;
    }

    final created = await repository.createGroup(name: name);
    final normalized = created.adminId.isEmpty ? created.copyWith(adminId: currentUserId) : created;

    // Refrescar lista desde backend para asegurar que aparezca en “Propios”.
    try {
      _groups = await repository.findByMember(currentUserId);
    } catch (_) {
      _groups = [normalized, ..._groups];
    }
    notifyListeners();
  }

  Future<void> joinByToken(String token) async {
    if (kDebugMode) {
      debugPrint('[groups] joinByToken token="$token"');
    }
    final groupId = await repository.joinByInvitation(token);
    if (kDebugMode) {
      debugPrint('[groups] joinByToken success groupId="$groupId"');
    }
    await refreshGroup(groupId);
    await loadMyGroups();
  }

  Future<void> leaveGroup(String groupId) async {
    await repository.leaveGroup(groupId);
    _groups = _groups.where((g) => g.id != groupId).toList();
    notifyListeners();
  }

  Future<List<GroupQuizAssignment>> loadGroupAssignments(String groupId) async {
    final list = await repository.getGroupAssignments(groupId);
    if (kDebugMode) {
      debugPrint('[groups] loadGroupAssignments groupId=$groupId count=${list.length}');
    }
    _groups = _groups
        .map((g) => g.id == groupId ? g.copyWith(quizAssignments: list) : g)
        .toList();
    notifyListeners();
    return list;
  }

  Future<void> removeMember(String groupId, String memberId) async {
    await repository.removeMember(groupId: groupId, memberId: memberId);
    await refreshGroup(groupId);
  }

  Future<GroupInvitationToken> generateInvitation(String groupId) async {
    final token = await repository.generateInvitation(groupId);
    return token;
  }

  Future<List<GroupMember>?> getMembers(String groupId) async {
    try {
      final members = await repository.getGroupMembers(groupId);
      _groups = _groups
          .map((g) => g.id == groupId ? g.copyWith(members: members) : g)
          .toList();
      notifyListeners();
      return members;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> transferAdmin(String groupId, String newAdminId) async {
    await repository.transferAdmin(groupId: groupId, newAdminUserId: newAdminId);
    await refreshGroup(groupId);
  }

  Future<void> updateGroupInfo({required String groupId, String? name, String? description}) async {
    final updated = await repository.updateGroupInfo(
      groupId: groupId,
      name: name,
      description: description,
    );
    _groups = _groups.map((g) => g.id == groupId ? updated : g).toList();
    notifyListeners();
  }

  List<Group> joinedGroups() {
    final userId = _currentUserId;
    if (userId == null) return _groups;
    return _groups.where((g) => g.members.any((m) => m.userId == userId)).toList();
  }

  List<Group> ownedGroups() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return _groups.where((g) => g.adminId == userId).toList();
  }

  bool isCurrentUserAdmin(Group group) => group.adminId == _currentUserId;

  GroupMember? findMember(Group group, String userId) {
    for (final m in group.members) {
      if (m.userId == userId) return m;
    }
    return null;
  }
}
