import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../application/DataSource/IThemeRemoteDataSource.dart';
import '../../application/dto/ThemeListResponseDto.dart';


class ThemeRemoteDataSource implements IThemeRemoteDataSource {
  final String baseUrl;
  final http.Client cliente;

  ThemeRemoteDataSource({required this.baseUrl,  required http.Client cliente})
      : cliente = cliente ?? http.Client() {
    try {
      print('ThemeRemoteDataSource initialized with baseUrl=$baseUrl');
    } catch (_) {}
  }

  @override
  Future<ThemeListResponseDto> fetchThemes() async {
    const String path = '/explore/categories';
    final uri = Uri.parse('$baseUrl$path');

    try {
      print('ThemeRemoteDataSource.fetchThemes -> GET $uri');

      final response = await cliente.get(uri);

      print(
        'ThemeRemoteDataSource.fetchThemes -> Response status: ${response.statusCode} headers: ${response.headers}',
      );

      if (response.statusCode == 200) {


        final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        // PASO 2: Extraer la lista de temas usando la clave "categories"
        if (!jsonResponse.containsKey('categories')) {
          throw ServerException(message: 'Respuesta de temas no contiene la clave "categories".');
        }

        final List<dynamic> jsonList = jsonResponse['categories'] as List<dynamic>;

        // PASO 3: Pasar la lista extraída al DTO
        print('ThemeRemoteDataSource.fetchThemes -> SUCCESS, extracted ${jsonList.length} categories.');
        return ThemeListResponseDto.fromListJson(jsonList);

      } else {
        final msg = 'Fallo al cargar temas: ${response.statusCode} - ${response.body}';
        print('ThemeRemoteDataSource.fetchThemes -> $msg');
        throw ServerException(message: msg);
      }
    } catch (e, st) { // Se mantiene la captura de StackTrace para consistencia
      print('ThemeRemoteDataSource.fetchThemes -> Exception processing response: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }
}