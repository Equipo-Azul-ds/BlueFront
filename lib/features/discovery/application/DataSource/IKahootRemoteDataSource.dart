import 'dart:async';

import '../../../../core/errors/exception.dart';
import '../../application/dto/KahootSearchresponseDto.dart';
import '../../application/model/kahoot_Model.dart';


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