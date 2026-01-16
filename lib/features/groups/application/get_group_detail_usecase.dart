import '../domain/repositories/GroupRepository.dart';

class GetGroupDetailInput {
  final String groupId;
  final String currentUserId;

  GetGroupDetailInput({required this.groupId, required this.currentUserId});
}

class GroupDetailMemberDto {
  final String userId;
  final String role;
  final String joinedAt;
  final int completedQuizzes;

  GroupDetailMemberDto({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.completedQuizzes,
  });
}

class GetGroupDetailOutput {
  final String id;
  final String name;
  final String? description;
  final String adminId;
  final List<GroupDetailMemberDto> members;
  final String createdAt;
  final String updatedAt;

  GetGroupDetailOutput({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });
}

class GetGroupDetailUseCase {
  final GroupRepository groupRepository;

  GetGroupDetailUseCase({required this.groupRepository});

  Future<GetGroupDetailOutput> execute(GetGroupDetailInput input) async {
    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (!group.isMember(input.currentUserId)) {
      throw Exception('User ${input.currentUserId} is not a member of group ${input.groupId}');
    }

    final members = group.members
        .map(
          (m) => GroupDetailMemberDto(
            userId: m.userId,
            role: m.role.value,
            joinedAt: m.joinedAt.toIso8601String(),
            completedQuizzes: m.completedQuizzes,
          ),
        )
        .toList();

    return GetGroupDetailOutput(
      id: group.id,
      name: group.name,
      description: group.description,
      adminId: group.adminId,
      members: members,
      createdAt: group.createdAt.toIso8601String(),
      updatedAt: group.updatedAt.toIso8601String(),
    );
  }
}
