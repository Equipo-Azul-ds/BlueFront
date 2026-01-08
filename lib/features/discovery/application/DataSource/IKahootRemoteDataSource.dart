import 'dart:async';
import '../../application/dto/KahootSearchresponseDto.dart';



abstract class IKahootRemoteDataSource {
  Future<KahootSearchResponseDto> fetchKahoots({
    String? query,
    List<String> themes,
    String orderBy,
    String order,
  });

  Future<KahootSearchResponseDto> fetchFeaturedKahoots({
    int? limit,
  });
}