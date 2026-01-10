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
      isAdmin: json['isAdmin'] == true || json['isAdmin'] == 1,
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
  final PaginationInfo pagination; // El getter que te falta

  PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => UserDto.fromJson(i))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}