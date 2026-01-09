import '../domain/repositories/GroupRepository.dart';

class GetUserGroupsInput {
  final String currentUserId;

  GetUserGroupsInput({required this.currentUserId});
}

class GetUserGroupsOutput {
  final String id;
  final String name;
  final String adminId;
  final int memberCount;
  final String createdAt;

  GetUserGroupsOutput({
    required this.id,
    required this.name,
    required this.adminId,
    required this.memberCount,
    required this.createdAt,
  });
}

class GetUserGroupsUseCase {
  final GroupRepository groupRepository;

  GetUserGroupsUseCase({required this.groupRepository});

  Future<List<GetUserGroupsOutput>> execute(GetUserGroupsInput input) async {
    final groups = await groupRepository.findByMember(input.currentUserId);
    return groups
        .map(
          (g) => GetUserGroupsOutput(
            id: g.id,
            name: g.name,
            adminId: g.adminId,
            memberCount: g.members.length,
            createdAt: g.createdAt.toIso8601String(),
          ),
        )
        .toList();
  }
}
