import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../Aplication/DataSource/IUserDataSource.dart';
import '../../Aplication/dtos/userDTO.dart';
import '../../Aplication/dtos/user_query_params.dart';
import '../../Dominio/entidad/User.dart';



class UserRemoteDataSourceImpl implements IUserDataSource {
  final String baseUrl;
  final http.Client cliente;

  UserRemoteDataSourceImpl({required this.baseUrl, required this.cliente}) {
    try {
      print('UserRemoteDataSource initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  Uri _buildUri(String path, Map<String, dynamic> params) {
    final Map<String, dynamic> cleanParams = {};
    params.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          cleanParams[key] = value.join(',');
        } else {
          cleanParams[key] = value.toString();
        }
      }
    });

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: cleanParams.cast<String, String>());
    try {
      print('UserRemoteDataSource -> Building URI: $uri');
    } catch (_) {}
    return uri;
  }

  @override
  Future<PaginatedResponse> fetchUsers(UserQueryParams params) async {
    final uri = _buildUri(
      '/users',
      params.toMap(), // toMap() contiene q, limit, page, orderBy, order
    );

    try {
      print('UserRemoteDataSource.fetchUsers -> GET $uri');
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});
      print(
        'UserRemoteDataSource.fetchUsers -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        final List<UserDto> users = (jsonResponse['data'] as List)
            .map((item) => UserDto.fromJson(item as Map<String, dynamic>))
            .toList();

        return PaginatedResponse(
          data: users,
          pagination: jsonResponse['pagination'] as Map<String, dynamic>,
        );

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
  }

  // Implementaciones dummy para otras funciones
  @override
  Future<UserEntity> toggleUserStatus(String userId, String status) async {
    final uri = Uri.parse('$baseUrl/users/$userId');

    final response = await cliente.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer admin_token', // Ajustar según tu auth
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return UserDto.fromJson(json.decode(response.body)).toEntity();
    } else {
      throw ServerException(message: 'Error al cambiar estado del usuario');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId');

    final response = await cliente.delete(
      uri,
      headers: {
        'Authorization': 'Bearer admin_token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ServerException(message: 'Error al eliminar usuario');
    }
  }


}