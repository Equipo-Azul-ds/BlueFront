import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'common_pages/dashboard_page.dart';
import 'features/challenge/domain/repositories/single_player_game_repository.dart';
import 'features/challenge/infrastructure/repositories/single_player_game_repository_impl.dart';
import 'features/challenge/infrastructure/ports/slide_provider_impl.dart';
import 'features/challenge/application/use_cases/single_player_usecases.dart';
import 'features/challenge/application/ports/slide_provider.dart';
import 'features/challenge/presentation/blocs/single_player_challenge_bloc.dart';
import 'features/challenge/presentation/blocs/single_player_results_bloc.dart';
import 'features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import 'features/media/presentation/blocs/media_editor_bloc.dart';
import 'features/kahoot/presentation/pages/quiz_editor_page.dart';
import 'features/kahoot/presentation/pages/question_editor_page.dart';
import 'common_pages/template_selector_page.dart';
import 'features/kahoot/infrastructure/repositories/Quiz_Repository_Impl.dart';
import 'features/media/infrastructure/repositories/Media_Repository_Impl.dart';
import 'features/media/infrastructure/repositories/Storage_Provider_Repository_Impl.dart';
import 'features/kahoot/domain/repositories/QuizRepository.dart';
import 'features/media/domain/repositories/Media_Repository.dart';
import 'features/media/domain/repositories/Storage_Provider_Repository.dart';
import 'features/media/application/upload_media_usecase.dart';
import 'features/media/application/get_media_usecase.dart';
import 'features/media/application/delete_media_usecase.dart';
import 'features/kahoot/domain/entities/Quiz.dart';

import 'features/library/domain/repositories/library_repository.dart';
import 'features/library/infrastructure/repositories/mock_library_repository.dart';
import 'features/library/application/get_kahoots_use_cases.dart';
import 'features/library/application/get_kahoot_detail_use_case.dart';
import 'features/library/application/get_kahoot_progress_usecase.dart';
import 'features/library/application/toggle_favorite_use_case.dart';
import 'features/library/application/update_kahoot_progress_usecase.dart';
import 'features/library/presentation/providers/library_provider.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/kahoots_category_page.dart';
import 'features/library/presentation/pages/kahoot_detail_page.dart';

// API base URL configurable vía --dart-define=API_BASE_URL
// Por defecto apunta al backend desplegado en Railway
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://backcomun-production.up.railway.app',
);

void main() {
  // Mostrar en consola la URL base que la app está usando (útil para depuración)
  print('API_BASE_URL = $apiBaseUrl');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SlideProvider>(create: (_) => SlideProviderImpl()),
        Provider<SinglePlayerGameRepositoryImpl>(
          create: (context) => SinglePlayerGameRepositoryImpl(
            slideProvider: context.read<SlideProvider>(),
          ),
        ),
        Provider<SinglePlayerGameRepository>(
          create: (context) => context.read<SinglePlayerGameRepositoryImpl>(),
        ),
        Provider<GetAttemptStateUseCase>(
          create: (context) => GetAttemptStateUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
          ),
        ),
        Provider<StartAttemptUseCase>(
          create: (context) => StartAttemptUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
            slideProvider: context.read<SlideProvider>(),
            getAttemptStateUseCase: context.read<GetAttemptStateUseCase>(),
          ),
        ),
        Provider<SubmitAnswerUseCase>(
          create: (context) => SubmitAnswerUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
            slideProvider: context.read<SlideProvider>(),
          ),
        ),
        Provider<GetSummaryUseCase>(
          create: (context) =>
              GetSummaryUseCase(context.read<SinglePlayerGameRepository>()),
        ),
        ChangeNotifierProvider<SinglePlayerChallengeBloc>(
          create: (context) => SinglePlayerChallengeBloc(
            startAttemptUseCase: context.read<StartAttemptUseCase>(),
            getAttemptStateUseCase: context.read<GetAttemptStateUseCase>(),
            submitAnswerUseCase: context.read<SubmitAnswerUseCase>(),
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
          ),
        ),

        ChangeNotifierProvider<SinglePlayerResultsBloc>(
          create: (context) => SinglePlayerResultsBloc(
            repository: context.read<SinglePlayerGameRepository>(),
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
          ),
        ),
        //Estos son los proveedores para los repositorios (inyeccion de dependencias)
        // Repositorios con configuración mínima (ajusta baseUrl según tu entorno)
        Provider<QuizRepository>(
          create: (_) => QuizRepositoryImpl(baseUrl: apiBaseUrl),
        ),
        Provider<MediaRepository>(
          create: (_) => MediaRepositoryImpl(baseUrl: apiBaseUrl),
        ),
        Provider<StorageProviderRepository>(
          create: (_) => StorageProviderRepositoryImpl(baseUrl: apiBaseUrl),
        ),
        // Blocs / ChangeNotifiers
        ChangeNotifierProvider(
          create: (context) => QuizEditorBloc(context.read<QuizRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MediaEditorBloc(
            uploadUseCase: UploadMediaUseCase(
              mediaRepository: context.read<MediaRepository>(),
            ),
            getUseCase: GetMediaUseCase(
              mediaRepository: context.read<MediaRepository>(),
              storageProvider: context.read<StorageProviderRepository>(),
            ),
            deleteUseCase: DeleteMediaUseCase(
              mediaRepository: context.read<MediaRepository>(),
              storageProvider: context.read<StorageProviderRepository>(),
            ),
          ),
        ),
        Provider<LibraryRepository>(create: (_) => MockLibraryRepository()),
        Provider<GetCreatedKahootsUseCase>(
          create: (context) => GetCreatedKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetFavoriteKahootsUseCase>(
          create: (context) => GetFavoriteKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetInProgressKahootsUseCase>(
          create: (context) => GetInProgressKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetCompletedKahootsUseCase>(
          create: (context) => GetCompletedKahootsUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetKahootDetailUseCase>(
          create: (context) => GetKahootDetailUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        //Proveedor para el caso de uso de Toggle Favorite
        Provider<ToggleFavoriteUseCase>(
          create: (context) => ToggleFavoriteUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        // ACTUALIZACIÓN DE PROGRESO
        Provider<UpdateKahootProgressUseCase>(
          create: (context) => UpdateKahootProgressUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        Provider<GetKahootProgressUseCase>(
          create: (context) => GetKahootProgressUseCase(
            repository: context.read<LibraryRepository>(),
          ),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (context) => LibraryProvider(
            getCreated: context.read<GetCreatedKahootsUseCase>(),
            getFavorite: context.read<GetFavoriteKahootsUseCase>(),
            getInProgress: context.read<GetInProgressKahootsUseCase>(),
            getCompleted: context.read<GetCompletedKahootsUseCase>(),
            toggleFavorite: context.read<ToggleFavoriteUseCase>(),
            updateProgress: context.read<UpdateKahootProgressUseCase>(),
            getKahootProgress: context.read<GetKahootProgressUseCase>(),
          ),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trivvy',
        theme: ThemeData(
          fontFamily: 'Onest',
          primarySwatch: createMaterialColor(AppColor.primary),
          primaryColor: AppColor.primary,
          scaffoldBackgroundColor: AppColor.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColor.primary,
            iconTheme: IconThemeData(color: AppColor.onPrimary),
            titleTextStyle: TextStyle(
              color: AppColor.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: AppColor.secundary,
            foregroundColor: AppColor.onPrimary,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.secundary,
              foregroundColor: AppColor.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          iconTheme: IconThemeData(color: AppColor.primary),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: createMaterialColor(AppColor.primary),
          ).copyWith(secondary: AppColor.accent),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        initialRoute: '/dashboard',
        routes: {
          '/dashboard': (context) => DashboardPage(),
          // /create ahora acepta opcionalmente una `Quiz` como argumento (plantilla)
          '/create': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            Quiz? template;
            bool explicitClear = false;
            if (args is Quiz) template = args;
            if (args is Map && args['clear'] == true) explicitClear = true;
            // Si no se pasa plantilla, limpiamos cualquier quiz en edición previo
            // cuando se pida explícitamente limpiar (via FAB / create),
            // o cuando no haya un `currentQuiz` establecido, o cuando el
            // `currentQuiz` tenga un id vacío (indica una instancia local
            // que no debe reutilizarse para una nueva creación).
            final quizBloc = Provider.of<QuizEditorBloc>(
              context,
              listen: false,
            );
            final shouldClear =
                template == null &&
                (explicitClear ||
                    quizBloc.currentQuiz == null ||
                    (quizBloc.currentQuiz?.quizId.isEmpty ?? false));
            if (shouldClear) {
              quizBloc.clear();
            }
            return QuizEditorPage(template: template);
          },
          '/questionEditor': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, String>;
            return QuestionEditorPage(
              quizId: args['quizId']!,
              questionId: args['questionId']!,
            );
          },
          '/templateSelector': (context) => TemplateSelectorPage(),
          //Comentoados por ahora
          //'/joinLobby': (context) => JoinLobbyPage(), // Agregar si existe
          //'/gameDetail': (context) => GameDetailPage(), // Agregar si existe
          //'/discover': (context) => DiscoverScreen(), // Agregar si existe
          '/library': (context) => LibraryPage(), // Agregar si existe
          '/kahoots-category': (context) => const KahootsCategoryPage(),
          '/kahoot-detail': (context) => const KahootDetailPage(),
        },
        home: DashboardPage(), //Pagina inicial
      ),
    );
  }
}
