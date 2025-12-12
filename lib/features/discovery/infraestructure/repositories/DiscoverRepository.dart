import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../kahoot/domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';
import '../dataSource/kahootRemoteDataSource.dart';


class DiscoverRepository implements IDiscoverRepository{
  final KahootRemoteDataSource remoteDataSource;

  DiscoverRepository({required this.remoteDataSource}) {
    // Log de inicialización
    try { print('DiscoverRepository initialized'); } catch (_) {}
  }

  @override
  Future<Either<Failure, List<Kahoot>>> getKahoots({
    required String? query,
    required List<String> themes,
    required String orderBy,
    required String order,
  }) async {
    // Log de inicio de operación
    try { print('DiscoverRepository.getKahoots -> query=$query, themes=$themes'); } catch (_) {}

    try {
      final responseDto = await remoteDataSource.fetchKahoots(
        query: query,
        themes: themes,
        orderBy: orderBy,
        order: order,
      );

      // Log de éxito
      try { print('DiscoverRepository.getKahoots -> SUCCESS, ${responseDto.data.length} kahoots fetched'); } catch (_) {}
      return Right(responseDto.data);

    } on ServerException catch (e, st) { // Captura de excepción con StackTrace
      // Log de error
      print('DiscoverRepository.getKahoots -> ServerException: ${e.message}');
      print('Stacktrace: $st');
      return Left(NetworkFailure());
    } catch (e, st) { // Captura genérica con StackTrace
      // Log de error genérico
      print('DiscoverRepository.getKahoots -> Unexpected Exception: $e');
      print('Stacktrace: $st');
      return Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Kahoot>>> getFeaturedKahoots({
    int? limit,
  }) async {
    // Log de inicio de operación
    try { print('DiscoverRepository.getFeaturedKahoots -> limit=$limit'); } catch (_) {}

    try {
      final responseDto = await remoteDataSource.fetchFeaturedKahoots(
        limit: limit,
      );

      // Log de éxito
      try { print('DiscoverRepository.getFeaturedKahoots -> SUCCESS, ${responseDto.data.length} kahoots fetched'); } catch (_) {}
      return Right(responseDto.data);

    } on ServerException catch (e, st) { // Captura de excepción con StackTrace
      // Log de error
      print('DiscoverRepository.getFeaturedKahoots -> ServerException: ${e.message}');
      print('Stacktrace: $st');
      return Left(NetworkFailure());
    } catch (e, st) { // Captura genérica con StackTrace
      // Log de error genérico
      print('DiscoverRepository.getFeaturedKahoots -> Unexpected Exception: $e');
      print('Stacktrace: $st');
      return Left(UnknownFailure());
    }
  }
}