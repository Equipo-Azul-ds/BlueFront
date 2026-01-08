import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'common_pages/dashboard_page.dart';
import 'features/challenge/domain/repositories/single_player_game_repository.dart';
import 'features/challenge/infrastructure/repositories/single_player_game_repository_impl.dart';
import 'features/challenge/application/use_cases/single_player_usecases.dart';
import 'features/challenge/presentation/blocs/single_player_challenge_bloc.dart';
import 'features/challenge/presentation/blocs/single_player_results_bloc.dart';
import 'features/challenge/infrastructure/storage/single_player_attempt_tracker.dart';
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
import 'features/gameSession/domain/repositories/multiplayer_session_repository.dart';
import 'features/gameSession/domain/repositories/multiplayer_session_realtime.dart';
import 'features/gameSession/application/use_cases/multiplayer_session_usecases.dart';
import 'features/gameSession/infrastructure/datasources/multiplayer_session_remote_data_source.dart';
import 'features/gameSession/infrastructure/realtime/multiplayer_session_realtime_impl.dart';
import 'features/gameSession/infrastructure/repositories/multiplayer_session_repository_impl.dart';
import 'features/gameSession/infrastructure/socket/multiplayer_socket_client.dart';
import 'features/gameSession/presentation/controllers/multiplayer_session_controller.dart';

// API base URL configurable vía --dart-define=API_BASE_URL
// Por defecto apunta al backend desplegado en Railway
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://backcomun-gc5j.onrender.com');
// Token (UUID) usado mientras el backend mockea la verificación real.
const String apiAuthToken = String.fromEnvironment('API_AUTH_TOKEN', defaultValue: 'acde070d-8c4c-4f0d-9d8a-162843c10333');


void main() {
  // Mostrar en consola la URL base que la app está usando (útil para depuración)
  if (kDebugMode) {
    debugPrint('API_BASE_URL = $apiBaseUrl');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SinglePlayerGameRepositoryImpl>(
          create: (context) => SinglePlayerGameRepositoryImpl(
            baseUrl: apiBaseUrl,
            mockAuthToken: apiAuthToken,
          ),
        ),
        Provider<SinglePlayerGameRepository>(
          create: (context) => context.read<SinglePlayerGameRepositoryImpl>(),
        ),
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<SinglePlayerAttemptTracker>(
          create: (context) =>
              SinglePlayerAttemptTracker(context.read<FlutterSecureStorage>()),
        ),
        Provider<StartAttemptUseCase>(
          create: (context) => StartAttemptUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
          ),
        ),
        Provider<SubmitAnswerUseCase>(
          create: (context) => SubmitAnswerUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
          ),
        ),
        Provider<GetSummaryUseCase>(
          create: (context) =>
              GetSummaryUseCase(context.read<SinglePlayerGameRepository>()),
        ),
        Provider<GetAttemptStateUseCase>(
          create: (context) => GetAttemptStateUseCase(
            repository: context.read<SinglePlayerGameRepository>(),
          ),
        ),
        ChangeNotifierProvider<SinglePlayerChallengeBloc>(
          create: (context) => SinglePlayerChallengeBloc(
            startAttemptUseCase: context.read<StartAttemptUseCase>(),
            submitAnswerUseCase: context.read<SubmitAnswerUseCase>(),
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
            attemptTracker: context.read<SinglePlayerAttemptTracker>(),
          ),
        ),

        ChangeNotifierProvider<SinglePlayerResultsBloc>(
          create: (context) => SinglePlayerResultsBloc(
            getSummaryUseCase: context.read<GetSummaryUseCase>(),
          ),
        ),
        Provider<Dio>(
          create: (_) => Dio(
            BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
            ),
          ),
        ),
        //Estos son los proveedores para los repositorios (inyeccion de dependencias)
        // Repositorios con configuración mínima (ajusta baseUrl según tu entorno)
        Provider<QuizRepository>(create: (_)=> QuizRepositoryImpl(baseUrl: apiBaseUrl)),
        Provider<MediaRepository>(create: (_)=> MediaRepositoryImpl(baseUrl: apiBaseUrl)),
        Provider<StorageProviderRepository>(create: (_)=> StorageProviderRepositoryImpl(baseUrl: apiBaseUrl)),
        Provider<MultiplayerSessionRemoteDataSource>(
          create: (context) => MultiplayerSessionRemoteDataSourceImpl(
            dio: context.read<Dio>(),
            tokenProvider: () async => apiAuthToken,
          ),
        ),
        Provider<MultiplayerSocketClient>(
          create: (_) => MultiplayerSocketClient(
            baseUrl: apiBaseUrl,
            defaultTokenProvider: () async => apiAuthToken,
          ),
        ),
        Provider<MultiplayerSessionRepository>(
          create: (context) => MultiplayerSessionRepositoryImpl(
            remoteDataSource: context.read<MultiplayerSessionRemoteDataSource>(),
          ),
        ),
        Provider<MultiplayerSessionRealtime>(
          create: (context) => MultiplayerSessionRealtimeImpl(
            socketClient: context.read<MultiplayerSocketClient>(),
          ),
        ),
        Provider<InitializeHostLobbyUseCase>(
          create: (context) => InitializeHostLobbyUseCase(
            repository: context.read<MultiplayerSessionRepository>(),
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<ResolvePinFromQrTokenUseCase>(
          create: (context) => ResolvePinFromQrTokenUseCase(
            repository: context.read<MultiplayerSessionRepository>(),
          ),
        ),
        Provider<JoinLobbyUseCase>(
          create: (context) => JoinLobbyUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<LeaveSessionUseCase>(
          create: (context) => LeaveSessionUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<EmitHostStartGameUseCase>(
          create: (context) => EmitHostStartGameUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<EmitHostNextPhaseUseCase>(
          create: (context) => EmitHostNextPhaseUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<EmitHostEndSessionUseCase>(
          create: (context) => EmitHostEndSessionUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        Provider<SubmitPlayerAnswerUseCase>(
          create: (context) => SubmitPlayerAnswerUseCase(
            realtime: context.read<MultiplayerSessionRealtime>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MultiplayerSessionController(
            realtime: context.read<MultiplayerSessionRealtime>(),
            initializeHostLobbyUseCase: context.read<InitializeHostLobbyUseCase>(),
            resolvePinFromQrTokenUseCase:
                context.read<ResolvePinFromQrTokenUseCase>(),
            joinLobbyUseCase: context.read<JoinLobbyUseCase>(),
            leaveSessionUseCase: context.read<LeaveSessionUseCase>(),
            emitHostStartGameUseCase: context.read<EmitHostStartGameUseCase>(),
            emitHostNextPhaseUseCase: context.read<EmitHostNextPhaseUseCase>(),
            emitHostEndSessionUseCase: context.read<EmitHostEndSessionUseCase>(),
            submitPlayerAnswerUseCase: context.read<SubmitPlayerAnswerUseCase>(),
          ),
        ),
        // Blocs / ChangeNotifiers
        ChangeNotifierProvider(create: (context)=> QuizEditorBloc(context.read<QuizRepository>())),
        ChangeNotifierProvider(create: (context)=> MediaEditorBloc(
          uploadUseCase: UploadMediaUseCase(mediaRepository: context.read<MediaRepository>()),
          getUseCase: GetMediaUseCase(mediaRepository: context.read<MediaRepository>(), storageProvider: context.read<StorageProviderRepository>()),
          deleteUseCase: DeleteMediaUseCase(mediaRepository: context.read<MediaRepository>(), storageProvider: context.read<StorageProviderRepository>()),
        )),
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
              titleTextStyle: TextStyle(color: AppColor.onPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppColor.secundary, foregroundColor: AppColor.onPrimary),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.secundary, foregroundColor: AppColor.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            iconTheme: IconThemeData(color: AppColor.primary),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: createMaterialColor(AppColor.primary)).copyWith(secondary: AppColor.accent),
            pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          ),
          initialRoute: '/dashboard',
          routes:{
            '/dashboard': (context)=> DashboardPage(),
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
              final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
              final shouldClear = template == null && (explicitClear || quizBloc.currentQuiz == null || (quizBloc.currentQuiz?.quizId.isEmpty ?? false));
              if (shouldClear) {
                quizBloc.clear();
              }
              return QuizEditorPage(template: template);
            },
            '/questionEditor': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
              return QuestionEditorPage(quizId: args['quizId']!, questionId: args['questionId']!);
            },
            '/templateSelector': (context) => TemplateSelectorPage(),
            //Comentoados por ahora
            //'/joinLobby': (context) => JoinLobbyPage(), // Agregar si existe
            //'/gameDetail': (context) => GameDetailPage(), // Agregar si existe
            //'/discover': (context) => DiscoverPage(), // Agregar si existe
            //'/library': (context) => LibraryPage(), // Agregar si existe
          },
          home: DashboardPage(),//Pagina inicial
      ),
    );
  }
}

