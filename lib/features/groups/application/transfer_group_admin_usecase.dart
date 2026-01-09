import '../domain/entities/GroupRole.dart';
import '../domain/repositories/GroupRepository.dart';

class TransferGroupAdminInput {
  final String groupId;
  final String currentUserId;
  final String newAdminUserId;
  final DateTime? now;

  TransferGroupAdminInput({
    required this.groupId,
    required this.currentUserId,
    required this.newAdminUserId,
    this.now,
  });
}

class TransferGroupAdminOutput {
  final String groupId;
  final String oldAdminId;
  final String newAdminId;

  TransferGroupAdminOutput({
    required this.groupId,
    required this.oldAdminId,
    required this.newAdminId,
  });
}

class TransferGroupAdminUseCase {
  final GroupRepository groupRepository;

  TransferGroupAdminUseCase({required this.groupRepository});

  Future<TransferGroupAdminOutput> execute(
      TransferGroupAdminInput input) async {
    final now = input.now ?? DateTime.now();

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (group.adminId != input.currentUserId) {
      throw Exception('solo el administrador del grupo puede transferir el rol de administrador');
    }
    if (input.currentUserId == input.newAdminUserId) {
      throw Exception('El nuevo administrador debe ser diferente del administrador actual');
    }
    if (!group.isMember(input.newAdminUserId)) {
      throw Exception('El nuevo administrador debe ser un miembro del grupo');
    }

    final updatedMembers = group.members
        .map((m) => m.userId == group.adminId
            ? m.copyWith(role: GroupRole.member)
            : (m.userId == input.newAdminUserId
                ? m.copyWith(role: GroupRole.admin)
                : m))
        .toList();

    final updatedGroup = group.copyWith(
      adminId: input.newAdminUserId,
      members: updatedMembers,
      updatedAt: now,
    );

    await groupRepository.save(updatedGroup);

    return TransferGroupAdminOutput(
      groupId: updatedGroup.id,
      oldAdminId: input.currentUserId,
      newAdminId: input.newAdminUserId,
    );
  }
}
