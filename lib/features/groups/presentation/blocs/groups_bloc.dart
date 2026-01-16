import 'package:flutter/foundation.dart';

import '../../domain/entities/Group.dart';
import '../../domain/entities/GroupMember.dart';
import '../../domain/entities/GroupInvitationToken.dart';
import '../../domain/entities/GroupQuizAssignment.dart';
import '../../domain/entities/GroupLeaderboardEntry.dart';
import '../../domain/repositories/GroupRepository.dart';
import '../../../user/presentation/blocs/auth_bloc.dart';

class GroupsBloc extends ChangeNotifier {
  final GroupRepository repository;
  final AuthBloc auth;
  // Repo de usuarios para resolver nombres si el endpoint de grupos no los retorna
  final dynamic userRepository; 

  GroupsBloc({
    required this.repository, 
    required this.auth,
    this.userRepository,
  });

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
      var fresh = await repository.getGroupDetail(groupId);
      
      // Combinar con datos existentes para no perder info de la vista de lista (roles, contadores)
      // si el endpoint de detalle no los retorna.
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) {
        final existing = _groups[idx];
        String? role = fresh.currentUserRole ?? existing.currentUserRole;
        int? countSnapshot;
        
        // Si no vienen miembros y el conteo es 0, preservar el conteo del snapshot anterior
        if (fresh.members.isEmpty && fresh.memberCount == 0 && existing.memberCount > 0) {
          countSnapshot = existing.memberCount;
        }
        
        fresh = fresh.copyWith(
          userRoleSnapshot: role, 
          memberCountSnapshot: countSnapshot
        );
      }

      _groups = _groups.map((g) => g.id == groupId ? fresh : g).toList();
      notifyListeners();
      return fresh;
    } catch (e) {
      if (kDebugMode) {
         print('[GroupsBloc] refreshGroup failed for $groupId: $e');
      }
      // No setear _error global para no afectar la lista principal
      // No eliminar el grupo automáticamente si falla la carga de detalles (resiliencia)
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

  Future<void> deleteGroup(String groupId) async {
    await repository.deleteGroup(groupId);
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
      final membersRaw = await repository.getGroupMembers(groupId);
      
      // Enriquecer con nombres si faltan y tenemos el repo
      List<GroupMember> finalMembers = [];
      if (userRepository != null) {
        // Obtenemos los usuarios uno por uno (limitación actual del backend)
        // Optimizacion: intentar getOneById
        final futures = membersRaw.map((m) async {
          if (m.userName.isNotEmpty) return m; // Ya tiene nombre
          try {
             // Asumimos que userRepository es UserRepository
             // importamos '../../user/domain/repositories/UserRepository.dart'; idealmente
             // Como es dynamic, usamos invocación dinámica o casteamos si importáramos
             final user = await (userRepository).getOneById(m.userId);
             if (user != null) {
               final name = user.userName.isNotEmpty ? user.userName : user.email;
               return m.copyWith(userName: name);
             }
          } catch (_) {}
          return m;
        });
        finalMembers = await Future.wait(futures);
      } else {
        finalMembers = membersRaw;
      }

      _groups = _groups
          .map((g) => g.id == groupId ? g.copyWith(members: finalMembers) : g)
          .toList();
      notifyListeners();
      return finalMembers;
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

  Future<void> assignQuiz({
    required String groupId,
    required String quizId,
    required DateTime availableFrom,
    required DateTime availableUntil,
  }) async {
    await repository.assignQuizToGroup(
      groupId: groupId,
      quizId: quizId,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
    );
    // Recargar asignaciones para actualizar la lista en UI
    await loadGroupAssignments(groupId);
  }

  Future<List<GroupLeaderboardEntry>> getLeaderboard(String groupId) async {
    return await repository.getGroupLeaderboard(groupId);
  }

  List<Group> joinedGroups() {
    final userId = _currentUserId;
    if (userId == null) return []; 
    // En la vista resumen /groups, asumimos que todos los grupos en _groups pertenecen al usuario.
    // Filtrar los que NO administra.
    return _groups.where((g) => !g.isAdmin(userId)).toList();
  }

  List<Group> ownedGroups() {
    final userId = _currentUserId;
    if (userId == null) return [];
    // Filtrar los que SÍ administra.
    return _groups.where((g) => g.isAdmin(userId)).toList();
  }

  bool isCurrentUserAdmin(Group group) {
    final uid = _currentUserId;
    return uid != null && group.isAdmin(uid);
  }

  GroupMember? findMember(Group group, String userId) {
    for (final m in group.members) {
      if (m.userId == userId) return m;
    }
    return null;
  }
}
