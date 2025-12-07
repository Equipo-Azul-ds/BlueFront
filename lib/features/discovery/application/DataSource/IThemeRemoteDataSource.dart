
import '../dto/ThemeListResponseDto.dart';

abstract class IThemeRemoteDataSource {

  Future<ThemeListResponseDto> fetchThemes();
}