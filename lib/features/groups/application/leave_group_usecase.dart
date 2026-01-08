import '../domain/repositories/GroupRepository.dart';

class LeaveGroupInput {
  final String groupId;
  final String currentUserId;
  final DateTime? now;

  LeaveGroupInput({
    required this.groupId,
    required this.currentUserId,
    this.now,
  });
}

class LeaveGroupOutput {
  final String groupId;
  final bool left;

  LeaveGroupOutput({required this.groupId, required this.left});
}

class LeaveGroupUseCase {
  final GroupRepository groupRepository;

  LeaveGroupUseCase({required this.groupRepository});

  Future<LeaveGroupOutput> execute(LeaveGroupInput input) async {
    final now = input.now ?? DateTime.now();

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (group.adminId == input.currentUserId) {
      throw Exception('El administrador no puede abandonar el grupo sin transferir el rol de administrador');
    }

    if (!group.isMember(input.currentUserId)) {
      throw Exception('User ${input.currentUserId} is not a member of group ${input.groupId}');
    }

    final updatedGroup = group.removeMember(input.currentUserId, now);
    await groupRepository.save(updatedGroup);

    return LeaveGroupOutput(groupId: updatedGroup.id, left: true);
  }
}
