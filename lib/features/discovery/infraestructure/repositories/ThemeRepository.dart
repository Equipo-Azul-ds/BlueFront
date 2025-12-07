import 'package:Trivvy/features/discovery/application/model/Theme_Model.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/Repositories/IThemeRepositorie.dart';
import '../../domain/entities/theme.dart';
import '../dataSource/ThemeRemoteDataSource.dart';

class ThemeRepository implements IThemeRepository {
  final ThemeRemoteDataSource remoteDataSource;

  ThemeRepository({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ThemeEntity>>> getThemes() async {
    try {
      final responseDto = await remoteDataSource.fetchThemes();

      final List<ThemeEntity> themes = responseDto.data
          .map((model) => model.toEntity())
          .toList();

      return Right(themes);

    } on ServerException {

      return Left(NetworkFailure());
    }
  }
}
