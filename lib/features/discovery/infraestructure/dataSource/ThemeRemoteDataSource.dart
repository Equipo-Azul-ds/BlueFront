import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exception.dart';
import '../../application/DataSource/IThemeRemoteDataSource.dart';
import '../../application/dto/ThemeListResponseDto.dart';


class ThemeRemoteDataSource implements IThemeRemoteDataSource {
  final String baseUrl;
  final http.Client cliente;

  ThemeRemoteDataSource({required this.baseUrl,  required http.Client cliente})
      : cliente = cliente ?? http.Client();

  @override
  Future<ThemeListResponseDto> fetchThemes() async {
    const String path = '/explore/categories';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await cliente.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return ThemeListResponseDto.fromListJson(jsonList);
      } else {
        final msg = 'Fallo al cargar temas: ${response.statusCode} - ${response.body}';
        throw ServerException(message: msg);
      }
    } catch (e) {
      rethrow;
    }
  }
}