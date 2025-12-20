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

import 'TestDiscovery.mocks.dart';
// part 'TestDicovery.mocks.dart';
// ====================================================================





// ====================================================================
// 💡 CAMBIO 3: Añadir la anotación @GenerateMocks
// Le indica a build_runner que genere el mock para KahootRemoteDataSource
@GenerateMocks([KahootRemoteDataSource])
// ====================================================================


// Datos de prueba (mantener igual)
final tKahootModel = KahootModel(
  id: '123',
  title: 'Test Kahoot',
  description: 'Test Desc',
  kahootImage: 'url/image',
  visibility: 'public',
  status: 'published',
  themes: ['Science'],
  author: 'John Doe', // ✅ CORRECCIÓN: Campo 'author' (String)
  createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
  playCount: 50,
);
// ... (resto de los datos de prueba)
final tKahootModelList = [tKahootModel];
final tPaginationDto = PaginationDto(page: 1, limit: 10, totalCount: 1, totalPages: 1);
final tKahootSearchResponseDto = KahootSearchResponseDto(data: tKahootModelList, pagination: tPaginationDto,);
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

  // ===================================================================
  // GRUPO DE TEST 1: getKahoots (H6.1) - Búsqueda y Filtrado
  // ===================================================================

  group('getKahoots (Search and Filter)', () {
    const tQuery = 'Test';
    const tThemes = ['Science'];
    const tOrderBy = 'createdAt';
    const tOrder = 'desc';

    test(
        'debe retornar List<Kahoot> (Right) cuando la llamada al UserDataSource.dart es exitosa',
            () async {
          // Arrange: Simular el éxito, retornando el DTO completo
          when(mockRemoteDataSource.fetchKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          )).thenAnswer((_) async => tKahootSearchResponseDto);

          // Act: Llamar al método del repositorio
          final result = await repository.getKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          );

          // Assert: El repositorio debe retornar solo 'data' (List<KahootModel>) del DTO
          expect(result, Right(tKahootModelList));
          verify(mockRemoteDataSource.fetchKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          ));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });

    test(
        'debe retornar NetworkFailure (Left) cuando la llamada a la fuente de datos lanza una ServerException',
            () async {
          // Arrange: Simular la falla (ServerException)
          when(mockRemoteDataSource.fetchKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          )).thenThrow(tServerException);

          // Act: Llamar al método del repositorio
          final result = await repository.getKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          );

          // Assert: Verificar el retorno Left(NetworkFailure)
          expect(result, Left(NetworkFailure()));
          verify(mockRemoteDataSource.fetchKahoots(
            query: tQuery, themes: tThemes, orderBy: tOrderBy, order: tOrder,
          ));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });
  });

  // ===================================================================
  // GRUPO DE TEST 2: getFeaturedKahoots (H6.2) - Kahoots Destacados
  // ===================================================================

  group('getFeaturedKahoots', () {
    const tLimit = 10;

    test(
        'debe retornar List<Kahoot> (Right) cuando la llamada a la fuente de datos es exitosa',
            () async {
          // Arrange: Simular el éxito, retornando el DTO completo
          when(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit))

              .thenAnswer((_) async => tKahootSearchResponseDto);

          // Act: Llamar al método del repositorio
          final result = await repository.getFeaturedKahoots(limit: tLimit);

          // Assert: El repositorio extrae correctamente tKahootModelList.
          expect(result, Right(tKahootModelList));
          // ... (verificaciones)
        });

    test(
        'debe retornar NetworkFailure (Left) cuando la llamada a la fuente de datos lanza una ServerException',
            () async {
          // Arrange: Simular que fetchFeaturedKahoots lanza una ServerException
          when(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit))
              .thenThrow(tServerException);

          // Act: Llamar al método del repositorio
          final result = await repository.getFeaturedKahoots(limit: tLimit);

          // Assert: Verificar que el resultado es Left con NetworkFailure
          expect(result, Left(NetworkFailure()));
          verify(mockRemoteDataSource.fetchFeaturedKahoots(limit: tLimit));
          verifyNoMoreInteractions(mockRemoteDataSource);
        });
  });
}