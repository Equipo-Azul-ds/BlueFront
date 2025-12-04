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
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}


class KahootSearchResponseDto {
  final List<KahootModel> data;
  final PaginationDto pagination;

  KahootSearchResponseDto({
    required this.data,
    required this.pagination,
  });

  factory KahootSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>;
    final paginationJson = json['pagination'] as Map<String, dynamic>;

    final List<KahootModel> kahoots = dataList
        .map((item) => KahootModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return KahootSearchResponseDto(
      data: kahoots,
      pagination: PaginationDto.fromJson(paginationJson),
    );
  }
}