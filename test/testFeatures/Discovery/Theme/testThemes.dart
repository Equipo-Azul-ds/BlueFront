import 'package:Trivvy/features/discovery/application/dto/ThemeListResponseDto.dart';
import 'package:Trivvy/features/discovery/application/model/Theme_Model.dart';
import 'package:Trivvy/features/discovery/domain/entities/theme.dart';
import 'package:Trivvy/features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:Trivvy/core/errors/exception.dart';
import 'package:Trivvy/core/errors/failures.dart';
import 'Themetest.mocks.dart';


void main() {
  late ThemeRepository repository;
  // Usamos el mock de la interfaz del Data Source
  late MockThemeRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockThemeRemoteDataSource();
    repository = ThemeRepository(remoteDataSource: mockRemoteDataSource);
  });

  // Datos de prueba
  final tThemeModel = ThemeModel(
    id: '1', name: 'Science', description: 'Desc', kahootCount: 10,
  );
  final tThemeEntity = tThemeModel.toEntity();
  final tThemeListDto = ThemeListResponseDto(data: [tThemeModel]);

  group('getThemes', () {
    test('debe retornar List<ThemeEntity> si la llamada al DataSource es exitosa', () async {
      // Arrange: Simular el éxito del Data Source
      when(mockRemoteDataSource.fetchThemes())
          .thenAnswer((_) async => tThemeListDto);

      // Act
      final result = await repository.getThemes();

      // Assert
      verify(mockRemoteDataSource.fetchThemes());
      // Verifica que el resultado sea Right(List<ThemeEntity>)
      expect(result, Right<Failure, List<ThemeEntity>>([tThemeEntity]));
    });

    test('debe retornar NetworkFailure si la llamada falla con ServerException', () async {
      // Arrange: Simular la falla del Data Source
      when(mockRemoteDataSource.fetchThemes())
          .thenThrow(ServerException(message: 'Error 500'));

      // Act
      final result = await repository.getThemes();

      // Assert
      verify(mockRemoteDataSource.fetchThemes());
      // Verifica que el resultado sea Left(NetworkFailure)
      expect(result, Left<Failure, List<ThemeEntity>>(NetworkFailure()));
    });
  });
}