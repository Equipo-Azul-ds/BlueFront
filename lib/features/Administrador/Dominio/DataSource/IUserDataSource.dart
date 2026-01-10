import 'package:http/http.dart';

import '../../Aplication/dtos/userDTO.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/entidad/User.dart';





abstract class IUserDataSource {
  Future<PaginatedResponse> fetchUsers(UserQueryParams params);
  Future<UserEntity> toggleUserStatus(String userId, String status);
  Future<void> deleteUser(String userId);
  Future<UserEntity> toggleAdminStatus(String userId, bool currentlyIsAdmin);
}