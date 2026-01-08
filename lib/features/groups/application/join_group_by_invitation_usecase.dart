import '../domain/entities/GroupMember.dart';
import '../domain/entities/GroupRole.dart';
import '../domain/repositories/GroupRepository.dart';

class JoinGroupByInvitationInput {
  final String token;
  final String currentUserId;
  final DateTime? now;

  JoinGroupByInvitationInput({
    required this.token,
    required this.currentUserId,
    this.now,
  });
}

class JoinGroupByInvitationOutput {
  final String groupId;
  final String joinedAs;

  JoinGroupByInvitationOutput({
    required this.groupId,
    required this.joinedAs,
  });
}

class JoinGroupByInvitationUseCase {
  final GroupRepository groupRepository;

  JoinGroupByInvitationUseCase({required this.groupRepository});

  Future<JoinGroupByInvitationOutput> execute(
      JoinGroupByInvitationInput input) async {
    final now = input.now ?? DateTime.now();

    final group = await groupRepository.findByInvitationToken(input.token);
    if (group == null) {
      throw Exception('Invalid invitation token');
    }

    final invitation = group.invitation;
    if (invitation == null) {
      throw Exception('This group has no active invitation');
    }

    if (invitation.isExpired(now: now)) {
      throw Exception('Invitation token has expired');
    }

    // Regla: máximo 5 miembros free (solo logging como en backend)
    if (group.members.length >= 5) {
      // ignore: avoid_print
      print('Grupo alcanzó el límite free de 5 miembros (dominio no lo rompe).');
    }

    final member = GroupMember(
      groupId: group.id,
      userId: input.currentUserId,
      role: GroupRole.member,
      joinedAt: now,
      completedQuizzes: 0,
    );

    final updatedGroup = group.addMember(member, now);
    await groupRepository.save(updatedGroup);

    return JoinGroupByInvitationOutput(
      groupId: updatedGroup.id,
      joinedAs: 'member',
    );
  }
}
