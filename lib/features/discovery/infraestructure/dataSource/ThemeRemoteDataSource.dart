import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../application/dto/ThemeListResponseDto.dart';
import '../../domain/DataSource/IThemeRemoteDataSource.dart';


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
        final dynamic jsonBody = jsonDecode(response.body);
        
        return ThemeListResponseDto.fromDynamicJson(jsonBody);

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