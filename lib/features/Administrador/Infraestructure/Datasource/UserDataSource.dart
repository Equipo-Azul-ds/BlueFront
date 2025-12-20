import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../Aplication/DataSource/IUserDataSource.dart';
import '../../Aplication/dtos/userDTO.dart';
import '../../Aplication/dtos/user_query_params.dart';


// Asumo que PaginatedResponse es un modelo auxiliar en el Data Layer

class UserRemoteDataSourceImpl implements IUserDataSource {
  final String baseUrl = "https://bec2a32a-edf0-42b0-bfef-20509e9a5a17.mock.pstmn.io";
  final http.Client cliente;
  final String baseUrl2;

  UserRemoteDataSourceImpl({required this.baseUrl2, required this.cliente}) {
    // Log de inicialización consistente con kahootRemoteDataSource.dart
    try {
      print('UserRemoteDataSource initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  // Método auxiliar para construir URI (Consistente con kahootRemoteDataSource.dart)
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
    // Usar la ruta '/users' según api.docx
    final uri = _buildUri(
      '/users',
      params.toMap(), // toMap() contiene q, limit, page, orderBy, order
    );

    try {
      // Logging antes de la petición (Consistente con kahootRemoteDataSource.dart)
      print('UserRemoteDataSource.fetchUsers -> GET $uri');
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});
      print(
        'UserRemoteDataSource.fetchUsers -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Mapear la lista de DTOs y la información de paginación
        final List<UserDto> users = (jsonResponse['data'] as List)
            .map((item) => UserDto.fromJson(item as Map<String, dynamic>))
            .toList();

        return PaginatedResponse(
          data: users,
          pagination: jsonResponse['pagination'] as Map<String, dynamic>,
        );

      } else if (response.statusCode == 400) {
        // Manejo de 400 Bad Request consistente con kahootRemoteDataSource.dart
        throw ServerException(message: "400: Parámetros de consulta inválidos.");
      } else {
        // Manejo de otros errores (Consistente con kahootRemoteDataSource.dart)
        final msg = 'Fallo al cargar usuarios: ${response.statusCode} - ${response.body}';
        print('UserRemoteDataSource.fetchUsers -> $msg');
        throw ServerException(message: msg);
      }
    } catch (e, st) {
      // Captura genérica con StackTrace (Consistente con kahootRemoteDataSource.dart)
      print('UserRemoteDataSource.fetchUsers -> Exception performing HTTP GET: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }

  // Implementaciones dummy para otras funciones
  @override
  Future<void> blockUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String userId) async {
    throw UnimplementedError();
  }
}