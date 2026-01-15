import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Trivvy/features/discovery/domain/Repositories/IDiscoverRepository.dart';
import 'package:Trivvy/features/discovery/domain/entities/kahoot.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:Trivvy/features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'package:Trivvy/features/discovery/domain/entities/theme.dart';


class MockThemeRepo extends Mock implements ThemeRepository {}
class MockDiscoverRepo extends Mock implements IDiscoverRepository {}

Future<void> laApiDeDescubrimientoEstaDisponible(WidgetTester tester) async {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<ThemeRepository>()) await getIt.reset();

  final mockTheme = MockThemeRepo();
  final mockDiscover = MockDiscoverRepo();

  // Mock para las categorías iniciales (Historia, Arte)
  when(() => mockTheme.getThemes()).thenAnswer((_) async => Right([
    ThemeVO(name: 'Historia'),
    ThemeVO(name: 'Arte'),
  ]));

  // Mock para la búsqueda de Matemáticas
  when(() => mockDiscover.getKahoots(
    query: any(named: 'query'),
    themes: any(named: 'themes'),
    orderBy: any(named: 'orderBy'),
    order: any(named: 'order'),
  )).thenAnswer((_) async => const Right([])); // Puedes devolver una lista con un Kahoot real aquí

  getIt.registerSingleton<ThemeRepository>(mockTheme);
  getIt.registerSingleton<IDiscoverRepository>(mockDiscover);
}