import 'package:Trivvy/core/errors/failures.dart';

import 'package:dartz/dartz.dart';

import '../Repositories/IThemeRepositorie.dart';
import '../entities/theme.dart';


class GetThemesUseCase {
  final IThemeRepository repository;

  GetThemesUseCase(this.repository);


  Future<Either<Failure, List<ThemeEntity>>> execute() async {
    return await repository.getThemes();
  }
}