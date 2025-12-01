// test/testFeatures/Discovery/TestDiscovery.dart

// ====================================================================
// 💡 CAMBIO 1: Importar anotaciones de Mockito
import 'package:Trivvy/features/discovery/application/dto/KahootSearchresponseDto.dart';
import 'package:Trivvy/features/discovery/application/model/kahoot_Model.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

// Importaciones de archivos de tu proyecto (ajustar la ruta según tu estructura)
import 'package:Trivvy/features/discovery/infraestructure/repositories/DiscoverRepository.dart';
import 'package:Trivvy/core/errors/exception.dart';
import 'package:Trivvy/core/errors/failures.dart';
import 'package:Trivvy/features/discovery/infraestructure/dataSource/kahootRemoteDataSource.dart';

import 'TestDicovery.mocks.dart';
// part 'TestDicovery.mocks.dart';
// ====================================================================





// ====================================================================
// 💡 CAMBIO 3: Añadir la anotación @GenerateMocks
// Le indica a build_runner que genere el mock para KahootRemoteDataSource
@GenerateMocks([KahootRemoteDataSource])
// ====================================================================


// Datos de prueba (mantener igual)
final tKahootModel = KahootModel(
  id: '1',
  title: 'Test Kahoot',
  visibility: 'publico',
  status: 'publico',
  themes: const [],
  authorId: 'AuthorA',
  createdAt: DateTime(2023),
);
// ... (resto de los datos de prueba)
final tKahootModelList = [tKahootModel];
final tKahootSearchResponseDto = KahootSearchResponseDto(data: tKahootModelList);
final tServerException = ServerException(message: 'Error de servidor');


void main() {
  // 💡 USAR LA CLASE MOCK GENERADA AUTOMÁTICAMENTE
  late MockKahootRemoteDataSource mockRemoteDataSource;
  late DiscoverRepository repository;

  // Configuración inicial antes de cada test
  setUp(() {
    // La clase MockKahootRemoteDataSource existe gracias a la generación del mock.
    mockRemoteDataSource = MockKahootRemoteDataSource();
    repository = DiscoverRepository(remoteDataSource: mockRemoteDataSource);
  });

  // ====================================================================
  // 🎯 Test para getKahoots
  // ====================================================================
  group('getKahoots', () {
    const tQuery = 'test query';
    const tThemes = <String>['tech'];
    const tOrderBy = 'createdAt';
    const tOrder = 'desc';

    test(
        'debe retornar una lista de Kahoot (Right) cuando la llamada al data source es exitosa y devuelve KahootSearchResponseDto',
            () async {
          // Arrange: Simular que fetchKahoots devuelve el DTO de respuesta exitoso
          when(mockRemoteDataSource.fetchKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          )).thenAnswer((_) async => tKahootSearchResponseDto);

          // Act: Llamar al método del repositorio
          final result = await repository.getKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          );

          // Assert: Verificar que el resultado es Right con la lista de Kahoots
          expect(result, Right(tKahootModelList));
          // Verificar que el método fetchKahoots fue llamado una vez con los parámetros correctos
          verify(mockRemoteDataSource.fetchKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          ));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });

    test(
        'debe retornar NetworkFailure (Left) cuando la llamada al data source lanza una ServerException',
            () async {
          // Arrange: Simular que fetchKahoots lanza una ServerException
          when(mockRemoteDataSource.fetchKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          )).thenThrow(tServerException);

          // Act: Llamar al método del repositorio
          final result = await repository.getKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          );

          // Assert: Verificar que el resultado es Left con NetworkFailure (como se maneja en DiscoverRepository)
          expect(result, Left(NetworkFailure())); //
          // Verificar que el método fetchKahoots fue llamado una vez
          verify(mockRemoteDataSource.fetchKahoots(
            query: tQuery,
            themes: tThemes,
            orderBy: tOrderBy,
            order: tOrder,
          ));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });
  });

  // ====================================================================
  // 🎯 Test para getFeaturedKahoots
  // ====================================================================
  group('getFeaturedKahoots', () {
    const tLimit = 5;

    test(
        'debe retornar una lista de Kahoot (Right) cuando la llamada a la fuente de datos es exitosa',
            () async {
          // Arrange: Simular que fetchFeaturedKahoots devuelve la lista de KahootModel
          when(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit))
              .thenAnswer((_) async => tKahootModelList);

          // Act: Llamar al método del repositorio
          final result = await repository.getFeaturedKahoots(limit: tLimit);

          // Assert: Verificar que el resultado es Right con la lista de Kahoots
          expect(result, Right(tKahootModelList));
          // Verificar que el método fetchFeaturedKahoots fue llamado una vez
          verify(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });

    test(
        'debe retornar NetworkFailure (Left) cuando la llamada a la fuente de datos lanza una ServerException',
            () async {
          // Arrange: Simular que fetchFeaturedKahoots lanza una ServerException
          when(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit))
              .thenThrow(tServerException);

          // Act: Llamar al método del repositorio
          final result = await repository.getFeaturedKahoots(limit: tLimit);

          // Assert: Verificar que el resultado es Left con NetworkFailure (como se maneja en DiscoverRepository)
          expect(result, Left(NetworkFailure())); //
          // Verificar que el método fetchFeaturedKahoots fue llamado una vez
          verify(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });
  });
}