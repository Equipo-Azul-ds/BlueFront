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
    final Map<String, String> cleanParams = {};

    params.forEach((key, value) {
      if (value == null) return;

      if (value is List) {

        final cleanList = value.where((e) => e.toString().trim().isNotEmpty).toList();
        if (cleanList.isNotEmpty) {
          cleanParams[key] = cleanList.join(',');
        }
      } else if (value is String) {
        if (value.trim().isNotEmpty) {
          cleanParams[key] = value.trim();
        }
      } else {
        cleanParams[key] = value.toString();
      }
    });

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: cleanParams);
    print('KahootRemoteDataSource -> URI final: $uri');
    return uri;
  }

  @override
  Future<KahootSearchResponseDto> fetchKahoots({
    String? query,
    List<String>? themes,
    String? orderBy,
    String? order,
    int? page,
    int? limit,
  }) async {
    final uri = _buildUri('/explore', {
      'q': query,
      'categories': themes,
      'orderBy': orderBy,
      'order': order,
      'page': page,
      'limit': limit,
    });

    try {
      // Forzamos el header de aceptación de JSON
      final response = await cliente.get(uri, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      });

      if (response.statusCode == 200) {
        // Usar utf8.decode para manejar correctamente caracteres especiales (acentos)
        final dynamic jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return KahootSearchResponseDto.fromDynamicJson(jsonBody);
      } else {
        // Log detallado para depuración
        print('Error en fetchKahoots: ${response.statusCode} - ${response.body}');
        throw ServerException(
          message: 'Server Error: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      print('Excepción en KahootRemoteDataSource: $e');
      print('Stacktrace: $stack');
      rethrow;
    }
  }

  @override
  Future<KahootSearchResponseDto> fetchFeaturedKahoots({int? limit}) async {
    final uri = _buildUri('/explore/featured', {'limit': limit});

    try {
      final response = await cliente.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        return KahootSearchResponseDto.fromDynamicJson(json.decode(response.body));
      } else {
        throw ServerException(message: '500: Error al recuperar contenido destacado');
      }
    } catch (e) {
      rethrow;
    }
  }
}
