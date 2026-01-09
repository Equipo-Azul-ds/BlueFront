import '../domain/repositories/GroupRepository.dart';

class UpdateGroupInfoInput {
  final String groupId;
  final String currentUserId;
  final String? name;
  final String? description;
  final DateTime? now;

  UpdateGroupInfoInput({
    required this.groupId,
    required this.currentUserId,
    this.name,
    this.description,
    this.now,
  });
}

class UpdateGroupInfoOutput {
  final String groupId;
  final String name;
  final String description;

  UpdateGroupInfoOutput({
    required this.groupId,
    required this.name,
    required this.description,
  });
}

class UpdateGroupInfoUseCase {
  final GroupRepository groupRepository;

  UpdateGroupInfoUseCase({required this.groupRepository});

  Future<UpdateGroupInfoOutput> execute(UpdateGroupInfoInput input) async {
    final now = input.now ?? DateTime.now();

    if ((input.name == null || input.name!.isEmpty) &&
        input.description == null) {
      throw Exception(
          'al menos un campo (nombre o descripción) debe ser proporcionado para la actualización');
    }

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (group.adminId != input.currentUserId) {
      throw Exception('Solo el administrador puede editar la información del grupo');
    }

    final updatedGroup = group.copyWith(
      name: input.name ?? group.name,
      description: input.description ?? group.description,
      updatedAt: now,
    );

    await groupRepository.save(updatedGroup);

    return UpdateGroupInfoOutput(
      groupId: updatedGroup.id,
      name: updatedGroup.name,
      description: updatedGroup.description ?? '',
    );
  }
}
