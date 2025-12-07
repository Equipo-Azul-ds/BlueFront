import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../kahoot/domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../dataSource/kahootRemoteDataSource.dart';


class DiscoverRepository implements IDiscoverRepository{
  final KahootRemoteDataSource remoteDataSource;


  DiscoverRepository({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Kahoot>>> getKahoots({
    required String? query,
    required List<String> themes,
    required String orderBy,
    required String order,
  }) async {
    try {
      final responseDto = await remoteDataSource.fetchKahoots(
        query: query,
        themes: themes,
        orderBy: orderBy,
        order: order,
      );

      return Right(responseDto.data);

    } on ServerException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Kahoot>>> getFeaturedKahoots({
    int? limit,
  }) async {
    try {

      final responseDto = await remoteDataSource.fetchFeaturedKahoots(
        limit: limit,
      );

      return Right(responseDto.data);

    } on ServerException {
      return Left(NetworkFailure());
    }
  }
}