import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/theme.dart';

abstract class IThemeRepository {

  Future<Either<Failure, List<ThemeVO>>> getThemes();
}