import 'package:Trivvy/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/Repositories/IThemeRepositorie.dart';
import '../../domain/entities/theme.dart';



class GetThemesUseCase {
  final IThemeRepository repository;

  GetThemesUseCase(this.repository);


  Future<Either<Failure, List<ThemeEntity>>> execute() async {
    return await repository.getThemes();
  }
}