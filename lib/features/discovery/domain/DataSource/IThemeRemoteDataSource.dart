

import '../../application/dto/ThemeListResponseDto.dart';

abstract class IThemeRemoteDataSource {

  Future<ThemeListResponseDto> fetchThemes();
}