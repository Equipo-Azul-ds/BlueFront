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
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }

  // Constructor para cuando el backend no envía paginación (casos de lista simple)
  factory PaginationDto.empty() => PaginationDto(
    page: 1,
    limit: 10,
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

  /// Factory modificado para detectar si viene una Lista o un Mapa
  factory KahootSearchResponseDto.fromDynamicJson(dynamic json) {
    // CASO NUEVO BACKEND: Es una lista directa []
    if (json is List) {
      final List<KahootModel> kahoots = json
          .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return KahootSearchResponseDto(
        data: kahoots,
        pagination: PaginationDto(
          page: 1,
          limit: kahoots.length,
          totalCount: kahoots.length,
          totalPages: 1,
        ),
      );
    }

    if (json is Map<String, dynamic>) {
      final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
      final paginationJson = json['pagination'] as Map<String, dynamic>?;

      final List<KahootModel> kahoots = dataList
          .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return KahootSearchResponseDto(
        data: kahoots,
        pagination: paginationJson != null
            ? PaginationDto.fromJson(paginationJson)
            : PaginationDto.empty(),
      );
    }

    throw Exception("Formato de respuesta desconocido");
  }
}