import 'package:uuid/uuid.dart';

import '../domain/entities/Group.dart';
import '../domain/entities/GroupMember.dart';
import '../domain/entities/GroupRole.dart';
import '../domain/repositories/GroupRepository.dart';

class CreateGroupInput {
  final String name;
  final String currentUserId;
  final DateTime? now;

  CreateGroupInput({
    required this.name,
    required this.currentUserId,
    this.now,
  });
}

class CreateGroupOutput {
  final String id;
  final String name;
  final String adminId;
  final int memberCount;
  final String createdAt;

  CreateGroupOutput({
    required this.id,
    required this.name,
    required this.adminId,
    required this.memberCount,
    required this.createdAt,
  });
}

class CreateGroupUseCase {
  final GroupRepository groupRepository;

  CreateGroupUseCase({required this.groupRepository});

  Future<CreateGroupOutput> execute(CreateGroupInput input) async {
    final now = input.now ?? DateTime.now();
    final groupId = const Uuid().v4();

    final adminMember = GroupMember(
      groupId: groupId,
      userId: input.currentUserId,
      role: GroupRole.admin,
      joinedAt: now,
      completedQuizzes: 0,
    );

    final group = Group(
      id: groupId,
      name: input.name,
      description: '',
      adminId: input.currentUserId,
      createdAt: now,
      updatedAt: now,
      members: [adminMember],
      quizAssignments: const [],
      completions: const [],
      invitation: null,
    );

    await groupRepository.save(group);

    return CreateGroupOutput(
      id: group.id,
      name: group.name,
      adminId: group.adminId,
      memberCount: group.members.length,
      createdAt: group.createdAt.toIso8601String(),
    );
  }
}
