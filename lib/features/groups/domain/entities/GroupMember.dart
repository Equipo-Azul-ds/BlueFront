import 'GroupRole.dart';

class GroupMember {
  final String groupId;
  final String userId;
  final String userName;
  final GroupRole role;
  final DateTime joinedAt;
  final int completedQuizzes;

  const GroupMember({
    required this.groupId,
    required this.userId,
    this.userName = '',
    required this.role,
    required this.joinedAt,
    this.completedQuizzes = 0,
  }) : assert(completedQuizzes >= 0);

  bool get isAdmin => role == GroupRole.admin;

  GroupMember copyWith({
    String? groupId,
    String? userId,
    String? userName,
    GroupRole? role,
    DateTime? joinedAt,
    int? completedQuizzes,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joinedAt'] ?? json['joined_at'];
    final nestedUser = json['user'] is Map<String, dynamic> ? (json['user'] as Map<String, dynamic>) : null;
    final uname = json['userName'] ?? json['username'] ?? json['user_name'] ?? json['name'] ?? json['fullName'] ?? json['full_name'] ??
      (nestedUser != null
        ? (nestedUser['userName'] ?? nestedUser['username'] ?? nestedUser['user_name'] ?? nestedUser['name'] ?? nestedUser['fullName'] ?? nestedUser['full_name'] ?? nestedUser['email'] ?? '')
        : '');
    return GroupMember(
      groupId: json['groupId'] as String? ?? json['group_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      userName: (uname is String) ? uname : '',
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
      'userName': userName,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'completedQuizzes': completedQuizzes,
    };
  }
}
