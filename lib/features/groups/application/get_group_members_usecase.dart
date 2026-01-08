import '../domain/repositories/GroupRepository.dart';

class GetGroupMembersInput {
  final String groupId;
  final String currentUserId;

  GetGroupMembersInput({required this.groupId, required this.currentUserId});
}

class GroupMemberDto {
  final String userId;
  final String role;
  final String joinedAt;
  final int completedQuizzes;

  GroupMemberDto({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.completedQuizzes,
  });
}

class GetGroupMembersOutput {
  final String name;
  final List<GroupMemberDto> members;

  GetGroupMembersOutput({required this.name, required this.members});
}

class GetGroupMembersUseCase {
  final GroupRepository groupRepository;

  GetGroupMembersUseCase({required this.groupRepository});

  Future<GetGroupMembersOutput> execute(GetGroupMembersInput input) async {
    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group ${input.groupId} not found');
    }

    if (!group.isMember(input.currentUserId)) {
      throw Exception('User ${input.currentUserId} is not a member of group ${input.groupId}');
    }

    final members = group.members
        .map(
          (m) => GroupMemberDto(
            userId: m.userId,
            role: m.role.value,
            joinedAt: m.joinedAt.toIso8601String(),
            completedQuizzes: m.completedQuizzes,
          ),
        )
        .toList();

    return GetGroupMembersOutput(name: group.name, members: members);
  }
}
