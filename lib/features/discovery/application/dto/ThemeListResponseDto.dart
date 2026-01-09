import '../model/Theme_Model.dart';

class ThemeListResponseDto {
  final List<ThemeModel> data;

  ThemeListResponseDto({required this.data});

  factory ThemeListResponseDto.fromDynamicJson(dynamic json) {
    if (json is List) {
      final themes = json
          .map((item) => ThemeModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ThemeListResponseDto(data: themes);
    }

    if (json is Map<String, dynamic>) {
      final List<dynamic> jsonList = json['categories'] as List<dynamic>? ?? [];
      final themes = jsonList
          .map((item) => ThemeModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ThemeListResponseDto(data: themes);
    }

    throw Exception("Formato de respuesta de temas no reconocido");
  }

  // Mantenemos este por compatibilidad si se usa en otros sitios
  factory ThemeListResponseDto.fromListJson(List<dynamic> listJson) {
    final themes = listJson
        .map((item) => ThemeModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return ThemeListResponseDto(data: themes);
  }
}