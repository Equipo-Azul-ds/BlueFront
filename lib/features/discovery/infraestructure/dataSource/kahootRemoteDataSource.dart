import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../application/DataSource/IKahootRemoteDataSource.dart';
import '../../application/dto/KahootSearchresponseDto.dart';
import '../../application/model/kahoot_Model.dart';


class KahootRemoteDataSource implements IKahootRemoteDataSource {
  final String baseUrl;
  final http.Client cliente;

  KahootRemoteDataSource({required this.baseUrl, required http.Client cliente})
      : cliente = cliente ?? http.Client();

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

    return Uri.parse('$baseUrl$path').replace(queryParameters: cleanParams.cast<String, String>());
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
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return KahootSearchResponseDto.fromJson(jsonResponse);
      } else if (response.statusCode == 400) {
        // Correcto manejo del 400 Bad Request
        throw ServerException(message: "400: Parámetros de búsqueda inválidos.");
      } else {
        final msg = 'Fallo al cargar Kahoots: ${response.statusCode} - ${response.body}';
        throw ServerException(message: msg);
      }
    } catch (e) {
      print('KahootRemoteDataSourceImpl.fetchKahoots -> Error: $e');
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
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);

        // CORRECCIÓN CLAVE: Usar el DTO para parsear la respuesta paginada.
        return KahootSearchResponseDto.fromJson(jsonBody);
      } else {
        final msg = 'Error al recuperar Kahoots destacados: ${response.statusCode} - ${response.body}';
        throw ServerException(message: msg);
      }
    } catch (e) {
      rethrow;
    }
  }
}
