import '../../Dominio/entidad/User.dart';


class UserDto {
  final String id;
  final String name;
  final String email;
  final String description;
  final String userType; // Como String en el JSON
  final String createdAt; // Como String en el JSON
  final String status; // Como String en el JSON

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.description,
    required this.userType,
    required this.createdAt,
    required this.status,
  });

  // Mapeo desde JSON (de la API)
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      description: json['description'] as String,
      userType: json['userType'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
    );
  }

  // **Mapeo a la Entidad de Dominio**
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      description: description,
      userType: UserEntity.parseUserType(userType),
      createdAt: DateTime.parse(createdAt),
      status: UserEntity.parseStatus(status),
    );
  }
}