import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/theme.dart';

abstract class IThemeRepository {

  Future<Either<Failure, List<ThemeVO>>> getThemes();

  Future<Either<Failure, void>> createTheme(String name);

  Future<Either<Failure, void>> updateTheme(String id, String name);

  Future<Either<Failure, void>> deleteTheme(String id);
}