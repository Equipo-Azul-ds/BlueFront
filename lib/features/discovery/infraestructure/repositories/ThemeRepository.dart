import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/Repositories/IThemeRepositorie.dart';
import '../../domain/entities/theme.dart';
import '../dataSource/ThemeRemoteDataSource.dart';

class ThemeRepository implements IThemeRepository {
  final ThemeRemoteDataSource remoteDataSource;

  ThemeRepository({required this.remoteDataSource}) {
    // Log de inicialización
    try { print('ThemeRepository initialized'); } catch (_) {}
  }

  @override
  Future<Either<Failure, List<ThemeVO>>> getThemes() async {
    // Log de inicio de operación
    try { print('ThemeRepository.getThemes -> Fetching themes...'); } catch (_) {}

    try {
      final responseDto = await remoteDataSource.fetchThemes();

      final List<ThemeVO> themes = responseDto.data
          .map((model) => model.toEntity())
          .toList();

      // Log de éxito
      try { print('ThemeRepository.getThemes -> SUCCESS, ${themes.length} themes fetched'); } catch (_) {}
      return Right(themes);

    } on ServerException catch (e, st) { // Captura de excepción con StackTrace
      // Log de error de servidor
      print('ThemeRepository.getThemes -> ServerException: $e');
      print('Stacktrace: $st');
      return Left(NetworkFailure());
    } catch (e, st) { // Captura genérica con StackTrace
      // Log de error genérico
      print('ThemeRepository.getThemes -> Unexpected Exception: $e');
      print('Stacktrace: $st');
      // Usar UnknownFailure
      return Left(UnknownFailure(detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createTheme(String name) async {
    try {
      await remoteDataSource.createTheme(name);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTheme(String id, String name) async {
    try {
      await remoteDataSource.updateTheme(id, name);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTheme(String id) async {
    try {
      await remoteDataSource.deleteTheme(id);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(detail: e.toString()));
    }
  }
}