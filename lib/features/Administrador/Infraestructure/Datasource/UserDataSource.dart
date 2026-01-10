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
    final adminId = await storage.read('userId');

    try {
      final response = await cliente.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': adminId ?? '',
          }
      );

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
  /*Future<PaginatedResponse> fetchUsers2(UserQueryParams params) async {
    final uri = _buildUri(
      '/users',
      params.toMap(),
    );

    try {
      print('UserRemoteDataSource.fetchUsers -> GET $uri');
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});
      print(
        'UserRemoteDataSource.fetchUsers -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {
        // 1. Decodificamos sin forzar el tipo Map
        final dynamic jsonBody = json.decode(response.body);

        // 2. Usamos el factory flexible que creamos arriba
        return PaginatedResponse.fromDynamicJson(jsonBody);
      } else if (response.statusCode == 400) {
        throw ServerException(message: "400: Parámetros de consulta inválidos.");
      } else {
        final msg = 'Fallo al cargar usuarios: ${response.statusCode} - ${response.body}';
        print('UserRemoteDataSource.fetchUsers -> $msg');
        throw ServerException(message: msg);
      }
    } catch (e, st) {
      print('UserRemoteDataSource.fetchUsers -> Exception performing HTTP GET: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }*/

  @override
  Future<UserEntity> toggleUserStatus(String userId, String status) async {

    final String action = (status.toLowerCase() == 'active') ? 'blockUser' : 'unblockUser';
    final uri = Uri.parse('$baseUrl/backoffice/$action/$userId');
    final token = await storage.read('token');
    final adminId = await storage.read('userId');


    final response = await cliente.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': adminId ?? '',
      },
    );

    if (response.statusCode == 200) {
      return UserDto.fromJson(json.decode(response.body)).toEntity();
    } else if (response.statusCode == 400) {
      throw ServerException(message: 'El usuario no existe');
    } else {
      throw ServerException(message: 'Error de servidor al cambiar estado');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Ajuste del path según la nueva especificación
    final uri = Uri.parse('$baseUrl/backoffice/user/$userId');
    final token = await storage.read('token');
    final adminId = await storage.read('userId');

    final response = await cliente.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': adminId ?? '',
      },
    );

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
    final adminId = await storage.read('userId');

    print('UserRemoteDataSource.toggleAdminStatus -> PATCH $uri');

    final response = await cliente.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': adminId ?? ''
        //'Authorization': 'Bearer $token',,
      },
    );

    if (response.statusCode == 200) {
      return UserDto.fromJson(json.decode(response.body)).toEntity();
    } else if (response.statusCode == 400) {
      throw ServerException(message: 'El usuario con el id dado no existe');
    } else if (response.statusCode == 401) {
      throw ServerException(message: 'No autorizado: se requiere rol de administrador');
    } else {
      throw ServerException(message: 'Error interno del servidor');
    }
  }


}