import '../../Dominio/entidad/User.dart';

class UserDto {
  final String id;
  final String name;
  final String email;
  final String description;
  final String userType;
  final String createdAt;
  final String status;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.description,
    required this.userType,
    required this.createdAt,
    required this.status,
  });

  // Mapeo individual de cada usuario con seguridad ante nulos
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      email: json['email']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      userType: json['userType']?.toString() ?? 'student',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      status: json['status']?.toString() ?? 'active',
    );
  }

  // Mapeo a la Entidad de Dominio
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      description: description,
      userType: UserEntity.parseUserType(userType),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
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

  // FACTORY CLAVE: Maneja tanto List<dynamic> como Map<String, dynamic>
  factory PaginatedResponse.fromDynamicJson(dynamic json) {
    // Caso Nuevo Backend: El JSON es directamente una Lista []
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

    // Caso Antiguo Backend: El JSON es un Objeto {"data": [], "pagination": {}}
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

    throw Exception("Formato de respuesta de usuarios no reconocido: ${json.runtimeType}");
  }
}