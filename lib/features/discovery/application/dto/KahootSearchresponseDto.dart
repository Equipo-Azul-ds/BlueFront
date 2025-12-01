import '../model/kahoot_Model.dart';

class KahootSearchResponseDto {
  final List<KahootModel> data;

  KahootSearchResponseDto({
    required this.data,
  });

  factory KahootSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>;
    final List<KahootModel> kahoots = dataList
        .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return KahootSearchResponseDto(
      data: kahoots,
    );
  }
}