import '../../Dominio/entidad/User.dart';

class UserDto {
  final String id;
  final String username;
  final String name;
  final String email;
  final String description;
  final String? avatarUrl;
  final String userType;
  final String createdAt;
  final String updatedAt;
  final bool isAdmin;
  final String status;

  const UserDto({
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      email: json['email']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      userType: json['userType']?.toString() ?? 'student',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      isAdmin: json['isAdmin'] is bool ? json['isAdmin'] : (json['isAdmin'] == 'true'),
      status: json['status']?.toString() ?? 'Active',
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      name: name,
      email: email,
      description: description,
      avatarUrl: avatarUrl,
      userType: UserEntity.parseUserType(userType),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      isAdmin: isAdmin,
      status: UserEntity.parseStatus(status),
    );
  }
}

class PaginatedResponse {
  final List<UserDto> data;
  final Map<String, dynamic> pagination;

  PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromDynamicJson(dynamic json) {
    // Caso: El backend devuelve directamente una lista []
    if (json is List) {
      final users = json
          .map((item) => UserDto.fromJson(item as Map<String, dynamic>))
          .toList();
      return PaginatedResponse(
        data: users,
        pagination: {
          'totalCount': users.length,
          'totalPages': 1,
          'page': 1,
          'limit': users.length,
        },
      );
    }

    if (json is Map<String, dynamic>) {
      final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
      final users = dataList
          .map((item) => UserDto.fromJson(item as Map<String, dynamic>))
          .toList();

      return PaginatedResponse(
        data: users,
        pagination: json['pagination'] as Map<String, dynamic>? ?? {
          'totalCount': users.length,
          'totalPages': 1,
          'page': 1,
          'limit': 10,
        },
      );
    }

    throw Exception("Formato de respuesta de usuarios no reconocido");
  }
}