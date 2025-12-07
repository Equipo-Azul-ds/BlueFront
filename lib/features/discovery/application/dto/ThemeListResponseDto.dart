import '../model/Theme_Model.dart';

class ThemeListResponseDto {
  final List<ThemeModel> data;

  ThemeListResponseDto({required this.data});


  factory ThemeListResponseDto.fromListJson(List<dynamic> listJson) {
    final themes = listJson
        .map((item) => ThemeModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return ThemeListResponseDto(data: themes);
  }
}