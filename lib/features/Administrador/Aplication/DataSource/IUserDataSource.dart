import 'package:http/http.dart';

import '../../Dominio/entidad/User.dart';
import '../dtos/userDTO.dart';
import '../dtos/user_query_params.dart';


// Modelo de respuesta para la paginación que maneja el UserDataSource.dart
class PaginatedResponse {
  final List<UserDto> data;
  final Map<String, dynamic> pagination;

  PaginatedResponse({required this.data, required this.pagination});
}

abstract class IUserDataSource {
  // Retorna el objeto de respuesta paginado (que contiene los DTOs)
  Future<PaginatedResponse> fetchUsers(UserQueryParams params);

  // Contratos para bloquear y eliminar (sólo se definen, no se implementan aquí)
  Future<UserEntity> toggleUserStatus(String userId, String status);
  Future<void> deleteUser(String userId);
}