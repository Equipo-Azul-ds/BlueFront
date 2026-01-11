import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../../../local/secure_storage.dart';
import '../../Aplication/dtos/userDTO.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/DataSource/IUserDataSource.dart';
import '../../Dominio/entidad/User.dart';




class UserRemoteDataSourceImpl implements IUserDataSource {
  final String baseUrl;
  final http.Client cliente;
  final storage = SecureStorage.instance;

  UserRemoteDataSourceImpl({required this.baseUrl, required this.cliente}) {
    try {
      print('UserRemoteDataSource initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  Uri _buildUri(String path, Map<String, dynamic> params) {
    final Map<String, String> cleanParams = {};

    params.forEach((key, value) {
      if (value != null) {
        if (value is String && value.trim().isNotEmpty) {
          cleanParams[key] = value.trim();
        } else if (value is int || value is bool) {
          cleanParams[key] = value.toString();
        }
      }
    });

    return Uri.parse('$baseUrl$path').replace(queryParameters: cleanParams);
  }

  @override
  Future<PaginatedResponse> fetchUsers(UserQueryParams params) async {
    final uri = _buildUri('/backoffice/users', params.toMap());
    final token = await storage.read('token');
    //final adminId = await storage.read('userId');
    final adminId = '9fa9df55-a70b-47cb-9f8d-ddb8d2c3c76a';

    try {
      final response = await cliente.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'userId': adminId ?? '',
          }
      );

      print('--- HTTP RESPONSE ---');
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return PaginatedResponse.fromJson(jsonBody);
      } else {
        throw ServerException(message: 'Error ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }



  @override
  Future<UserEntity> toggleUserStatus(String userId, String currentStatus) async {

    final bool isCurrentlyActive = currentStatus.trim().toLowerCase() == 'active';

    final String action = isCurrentlyActive ? 'blockUser' : 'unblockUser';
    final uri = Uri.parse('$baseUrl/backoffice/$action/$userId');
    final token = await storage.read('token');
    //final adminId = await storage.read('userId');
    final adminId = '9fa9df55-a70b-47cb-9f8d-ddb8d2c3c76a';

    print('--- HTTP REQUEST (Toggle Status) ---');
    print('URL: PATCH $uri');
    print('HEADERS: {"Content-Type": "application/json", "user": "$adminId"}');
    print('ACTION: $action para el usuario $userId de estado $currentStatus');

    final response = await cliente.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'user': adminId ?? '',
      },
    );
    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);

      final userData = jsonBody['user'];
      if (userData != null) {
        return UserDto.fromJson(userData).toEntity();
      }
      return UserDto.fromJson(jsonBody).toEntity();
    } else if (response.statusCode == 400) {
      throw ServerException(message: 'El usuario no existe');
    } else {
      throw ServerException(message: 'Error de servidor al cambiar estado');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    final uri = Uri.parse('$baseUrl/backoffice/user/$userId');
    final token = await storage.read('token');
    //final adminId = await storage.read('userId');
    final adminId = '9fa9df55-a70b-47cb-9f8d-ddb8d2c3c76a';

    final response = await cliente.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'user': adminId ?? '',
      },
    );
    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 204) {

      return;
    } else if (response.statusCode == 400) {
      throw ServerException(message: 'El usuario con el id dado no existe');
    } else if (response.statusCode == 401) {
      throw ServerException(message: 'No autorizado: requiere rol de administrador');
    } else {
      throw ServerException(message: 'Error al eliminar usuario: ${response.statusCode}');
    }
  }

  @override
  Future<UserEntity> toggleAdminStatus(String userId, bool currentlyIsAdmin) async {
    final String action = currentlyIsAdmin ? 'removeAdmin' : 'giveAdmin';
    final uri = Uri.parse('$baseUrl/backoffice/$action/$userId');
    final token = await storage.read('token');
    //final adminId = await storage.read('userId');
    final adminId = '9fa9df55-a70b-47cb-9f8d-ddb8d2c3c76a';

    print('UserRemoteDataSource.toggleAdminStatus -> PATCH $uri');

    final response = await cliente.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'user': adminId ?? ''
      },
    );
    print('--- HTTP RESPONSE ---');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      return UserDto.fromJson(jsonBody['user']).toEntity();
    } else if (response.statusCode == 400) {
      throw ServerException(message: 'El usuario con el id dado no existe');
    } else if (response.statusCode == 401) {
      throw ServerException(message: 'No autorizado: se requiere rol de administrador');
    } else {
      throw ServerException(message: 'Error interno del servidor');
    }
  }


}