import '../domain/repositories/GroupRepository.dart';

class RemoveGroupMemberInput {
  final String groupId;
  final String targetUserId;
  final String currentUserId;
  final DateTime? now;

  RemoveGroupMemberInput({
    required this.groupId,
    required this.targetUserId,
    required this.currentUserId,
    this.now,
  });
}

class RemoveGroupMemberOutput {
  final String groupId;
  final String removedUserId;

  RemoveGroupMemberOutput({
    required this.groupId,
    required this.removedUserId,
  });
}

class RemoveGroupMemberUseCase {
  final GroupRepository groupRepository;

  RemoveGroupMemberUseCase({required this.groupRepository});

  Future<RemoveGroupMemberOutput> execute(
      RemoveGroupMemberInput input) async {
    final now = input.now ?? DateTime.now();

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (group.adminId != input.currentUserId) {
      throw Exception('Solo el administrador del grupo puede realizar esta acción');
    }

    if (input.currentUserId == input.targetUserId) {
      throw Exception('El administrador no puede eliminarse a sí mismo del grupo');
    }

    if (!group.isMember(input.targetUserId)) {
      throw Exception('User ${input.targetUserId} is not a member of group ${input.groupId}');
    }

    final updatedGroup = group.removeMember(input.targetUserId, now);
    await groupRepository.save(updatedGroup);

    return RemoveGroupMemberOutput(
      groupId: updatedGroup.id,
      removedUserId: input.targetUserId,
    );
  }
}
