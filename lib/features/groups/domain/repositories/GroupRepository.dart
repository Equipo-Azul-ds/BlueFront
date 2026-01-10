import '../entities/Group.dart';
import '../entities/GroupMember.dart';
import '../entities/GroupInvitationToken.dart';
import '../entities/GroupQuizAssignment.dart';

abstract class GroupRepository {
  /// Obtiene un grupo por id; devuelve null si no existe.
  Future<Group?> findById(String groupId);

  /// Lista los grupos donde el usuario es miembro.
  Future<List<Group>> findByMember(String userId);

  /// Persiste o actualiza un grupo.
  Future<void> save(Group group);

  /// Busca un grupo a partir de un token de invitación; null si no existe o expiró.
  Future<Group?> findByInvitationToken(String token);

  // --- Endpoints específicos expuestos por el backend ---
  Future<Group> createGroup({required String name});
  Future<Group> getGroupDetail(String groupId);
  Future<List<GroupMember>> getGroupMembers(String groupId);
  Future<GroupInvitationToken> generateInvitation(String groupId);
  Future<String> joinByInvitation(String token);
  Future<void> leaveGroup(String groupId);
  Future<void> removeMember({required String groupId, required String memberId});
  Future<Group> updateGroupInfo({required String groupId, String? name, String? description});
  Future<void> transferAdmin({required String groupId, required String newAdminUserId});
  Future<GroupQuizAssignment> assignQuizToGroup({required String groupId, required String quizId, required DateTime availableUntil});
  Future<List<GroupQuizAssignment>> getGroupAssignments(String groupId);
}
