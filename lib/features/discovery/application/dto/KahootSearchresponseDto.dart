import '../model/kahoot_Model.dart';

class PaginationDto {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;

  PaginationDto({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
  });

  factory PaginationDto.fromJson(Map<String, dynamic> json) {
    return PaginationDto(
      page: _toInt(json['page']) ?? 1,
      limit: _toInt(json['limit']) ?? 20,
      totalCount: _toInt(json['totalCount']) ?? 0,
      totalPages: _toInt(json['totalPages']) ?? 1,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory PaginationDto.empty() => PaginationDto(
    page: 1,
    limit: 20,
    totalCount: 0,
    totalPages: 1,
  );
}

class KahootSearchResponseDto {
  final List<KahootModel> data;
  final PaginationDto pagination;

  KahootSearchResponseDto({
    required this.data,
    required this.pagination,
  });

  factory KahootSearchResponseDto.fromDynamicJson(dynamic json) {

    if (json is List) {
      final kahoots = json
          .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return KahootSearchResponseDto(
        data: kahoots,
        pagination: PaginationDto.empty(),
      );
    }


    if (json is Map<String, dynamic>) {
      final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
      final List<KahootModel> kahoots = dataList
          .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final paginationJson = json['pagination'] as Map<String, dynamic>?;

      return KahootSearchResponseDto(
        data: kahoots,
        pagination: paginationJson != null
            ? PaginationDto.fromJson(paginationJson)
            : PaginationDto.empty(),
      );
    }

    throw Exception("Formato de respuesta de Kahoot desconocido");
  }
}