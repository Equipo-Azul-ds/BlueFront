enum UserStatus { active, blocked }
enum UserType { student, teacher, admin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String description;
  final UserType userType;
  final DateTime createdAt;
  final UserStatus status;

  bool get isBlocked => status == UserStatus.blocked;
  String get formattedJoinDate => createdAt.toLocal().toString().split(' ')[0];

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.description,
    required this.userType,
    required this.createdAt,
    required this.status,
  });


  static UserType parseUserType(String type) {
    switch (type.toLowerCase()) {
      case 'teacher':
        return UserType.teacher;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.student;
    }
  }

  static UserStatus parseStatus(String status) {
    if (status.toLowerCase() == 'blocked') {
      return UserStatus.blocked;
    }
    return UserStatus.active;
  }
}