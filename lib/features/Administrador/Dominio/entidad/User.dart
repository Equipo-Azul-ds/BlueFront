enum UserStatus { active, blocked }
enum UserType { user, student, teacher, admin }

class UserEntity {
  final String id;
  final String username;
  final String name;
  final String email;
  final String description;
  final String? avatarUrl;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAdmin;
  final UserStatus status;

  bool get isBlocked => status == UserStatus.blocked;

  String get formattedJoinDate => createdAt.toLocal().toString().split(' ')[0];

  const UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.description,
    this.avatarUrl,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    required this.isAdmin,
    required this.status,
  });


  static UserType parseUserType(String type) {
    switch (type.toLowerCase()) {
      case 'teacher':
        return UserType.teacher;
      case 'admin':
        return UserType.admin;
      case 'student':
        return UserType.student;
      default:
        return UserType.user;
    }
  }


  static UserStatus parseStatus(String status) {
    if (status.toLowerCase() == 'blocked') {
      return UserStatus.blocked;
    }
    return UserStatus.active;
  }

  UserEntity copyWith({
    UserStatus? status,
    bool? isAdmin,
  }) {
    return UserEntity(
      id: id,
      username: username,
      name: name,
      email: email,
      description: description,
      avatarUrl: avatarUrl,
      userType: userType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      status: status ?? this.status,
    );
  }
}