import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../application/dto/KahootSearchresponseDto.dart';
import '../../domain/DataSource/IKahootRemoteDataSource.dart';


class KahootRemoteDataSource implements IKahootRemoteDataSource {
  final String baseUrl;
  final http.Client cliente;

  KahootRemoteDataSource({required this.baseUrl, required http.Client cliente})
      : cliente = cliente ?? http.Client() {
    try {
      print('KahootRemoteDataSource initialized with baseUrl=$baseUrl');
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
      // Nuevo log detallado de URI/request consistente con QuizRepositoryImpl
      print('KahootRemoteDataSource -> Building URI: $uri');
    } catch (_) {}
    return uri;
  }

  @override
  Future<KahootSearchResponseDto> fetchKahoots({
    String? query,
    List<String> themes = const [],
    String orderBy = 'createdAt',
    String order = 'desc',
  }) async {
    final uri = _buildUri(
      '/explore',
      {'q': query, 'categories': themes, 'orderBy': orderBy, 'order': order},
    );

    try {
      // Log antes de la petición
      print('KahootRemoteDataSource.fetchKahoots -> GET $uri');
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});
      // Log de respuesta
      print(
        'KahootRemoteDataSource.fetchKahoots -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {
        final dynamic jsonBody = json.decode(response.body);
        return KahootSearchResponseDto.fromDynamicJson(jsonBody);
      } else if (response.statusCode == 400) {
        // Correcto manejo del 400 Bad Request
        throw ServerException(message: "400: Parámetros de búsqueda inválidos.");
      } else {
        final msg = 'Fallo al cargar Kahoots: ${response.statusCode} - ${response.body}';
        print('KahootRemoteDataSource.fetchKahoots -> $msg');
        throw ServerException(message: msg);
      }
    } catch (e, st) { // Añadir StackTrace
      // Manejo de errores consistente con QuizRepositoryImpl
      print('KahootRemoteDataSource.fetchKahoots -> Exception performing HTTP GET: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }

  @override
  Future<KahootSearchResponseDto> fetchFeaturedKahoots({
    int? limit,
  }) async {
    final uri = _buildUri(
      '/explore/featured',
      {'limit': limit},
    );

    try {
      // Log antes de la petición
      print('KahootRemoteDataSource.fetchFeaturedKahoots -> GET $uri');
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});
      // Log de respuesta
      print(
        'KahootRemoteDataSource.fetchFeaturedKahoots -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {
        final dynamic jsonBody = json.decode(response.body);

        return KahootSearchResponseDto.fromDynamicJson(jsonBody);
      } else {
        final msg = 'Error al recuperar Kahoots destacados: ${response.statusCode} - ${response.body}';
        print('KahootRemoteDataSource.fetchFeaturedKahoots -> $msg');
        throw ServerException(message: msg);
      }
    } catch (e, st) { // Añadir StackTrace
      // Manejo de errores consistente con QuizRepositoryImpl
      print('KahootRemoteDataSource.fetchFeaturedKahoots -> Exception performing HTTP GET: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }
}