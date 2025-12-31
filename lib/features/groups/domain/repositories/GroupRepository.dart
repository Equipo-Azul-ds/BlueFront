import '../entities/Group.dart';

abstract class GroupRepository {
  /// Obtiene un grupo por id; devuelve null si no existe.
  Future<Group?> findById(String groupId);

  /// Lista los grupos donde el usuario es miembro.
  Future<List<Group>> findByMember(String userId);

  /// Persiste o actualiza un grupo.
  Future<void> save(Group group);

  /// Busca un grupo a partir de un token de invitación; null si no existe o expiró.
  Future<Group?> findByInvitationToken(String token);
}
