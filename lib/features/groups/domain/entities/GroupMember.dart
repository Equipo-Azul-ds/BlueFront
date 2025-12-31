import 'GroupRole.dart';

class GroupMember {
  final String groupId;
  final String userId;
  final GroupRole role;
  final DateTime joinedAt;
  final int completedQuizzes;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.completedQuizzes = 0,
  }) : assert(completedQuizzes >= 0);

  bool get isAdmin => role == GroupRole.admin;

  GroupMember copyWith({
    String? groupId,
    String? userId,
    GroupRole? role,
    DateTime? joinedAt,
    int? completedQuizzes,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joinedAt'] ?? json['joined_at'];
    return GroupMember(
      groupId: json['groupId'] as String? ?? json['group_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      role: GroupRole.fromValue(json['role'] as String? ?? 'member'),
      joinedAt: joinedRaw is String
          ? DateTime.parse(joinedRaw)
          : DateTime.now(),
      completedQuizzes: (json['completedQuizzes'] ?? json['completed_quizzes'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'userId': userId,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'completedQuizzes': completedQuizzes,
    };
  }
}
