import '../entities/GroupInvitationToken.dart';

abstract class GroupInvitationTokenGenerator {
  /// Genera un token de invitación con un TTL en días.
  Future<GroupInvitationToken> generate({required int ttlDays, required DateTime now});
}
