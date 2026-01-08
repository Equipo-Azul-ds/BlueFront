import '../domain/entities/Group.dart';
import '../domain/repositories/GroupRepository.dart';
import '../domain/services/group_invitation_token_generator.dart';

class GenerateGroupInvitationInput {
  final String groupId;
  final String currentUserId;
  final int? ttlDays;
  final DateTime? now;

  GenerateGroupInvitationInput({
    required this.groupId,
    required this.currentUserId,
    this.ttlDays,
    this.now,
  });
}

class GenerateGroupInvitationOutput {
  final String groupId;
  final String link;
  final String expiresAt;

  GenerateGroupInvitationOutput({
    required this.groupId,
    required this.link,
    required this.expiresAt,
  });
}

class GenerateGroupInvitationUseCase {
  final GroupRepository groupRepository;
  final GroupInvitationTokenGenerator tokenGenerator;

  GenerateGroupInvitationUseCase({
    required this.groupRepository,
    required this.tokenGenerator,
  });

  Future<GenerateGroupInvitationOutput> execute(
      GenerateGroupInvitationInput input) async {
    final now = input.now ?? DateTime.now();
    final ttlDays = input.ttlDays ?? 7;

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    if (group.adminId != input.currentUserId) {
      throw Exception('Solo el administrador del grupo puede generar invitaciones');
    }

    final token = await tokenGenerator.generate(ttlDays: ttlDays, now: now);

    final updatedGroup = group.copyWith(invitation: token, updatedAt: now);
    await groupRepository.save(updatedGroup);

    const baseUrl = 'http://QuizGo.app/groups/join/';
    final fullInvitationLink = '$baseUrl${token.token}';

    return GenerateGroupInvitationOutput(
      groupId: updatedGroup.id,
      link: fullInvitationLink,
      expiresAt: token.expiresAt.toIso8601String(),
    );
  }
}
