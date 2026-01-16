import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:Trivvy/features/Administrador/Presentacion/pages/NotificationAdminPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'features/discovery/presentation/pages/DiscoveryDetailPage.dart';
import 'local/secure_storage.dart';
import 'features/Administrador/Aplication/UseCases/DeleteUserUseCase.dart';
import 'features/Administrador/Aplication/UseCases/GetUserListUseCase.dart';
import 'features/Administrador/Aplication/UseCases/ToggleAdminUseCase.dart';
import 'features/Administrador/Aplication/UseCases/ToggleUserStatusUseCase.dart';
import 'features/Administrador/Dominio/DataSource/IUserDataSource.dart';
import 'features/Administrador/Dominio/Repositorio/IUserManagementRepository.dart';
import 'features/Administrador/Infraestructure/Datasource/UserDataSource.dart';
import 'features/Administrador/Infraestructure/repositories/UserRepository.dart';
import 'features/Administrador/Presentacion/pages/Admin_Page.dart';
import 'features/Administrador/Presentacion/pages/DashboardPage.dart';
import 'features/Administrador/Presentacion/pages/UserManagementPage.dart';
import 'features/Administrador/Presentacion/provider/DashboardProvider.dart';
import 'features/Notifications/Presentacion/Provider/NotificationProvider.dart';
import 'features/Administrador/Presentacion/provider/CategotyManagementProvider.dart';
import 'features/Administrador/Presentacion/provider/UserManagementProvider.dart';
import 'features/Notifications/Presentacion/pages/NotificationHistoryPage.dart';
import 'features/Notifications/infraestructura/Datasource/NotificationDatasource.dart';
import 'features/Notifications/infraestructura/Repositorios/NotificationRepository.dart';
import 'features/discovery/domain/Repositories/IDiscoverRepository.dart';
import 'features/discovery/infraestructure/dataSource/ThemeRemoteDataSource.dart';
import 'features/discovery/infraestructure/dataSource/kahootRemoteDataSource.dart';
import 'features/discovery/infraestructure/repositories/DiscoverRepository.dart';
import 'features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'features/discovery/application/usecases/GetThemeUseCase.dart';
import 'features/discovery/presentation/pages/discover_page.dart';

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
import 'features/report/domain/repositories/reports_repository.dart';
import 'features/report/infrastructure/repositories/reports_repository_impl.dart';
import 'features/report/application/use_cases/report_usecases.dart';
import 'features/report/presentation/blocs/reports_list_bloc.dart';
import 'features/gameSession/domain/repositories/multiplayer_session_repository.dart';
import 'features/gameSession/domain/repositories/multiplayer_session_realtime.dart';
import 'features/gameSession/application/use_cases/multiplayer_session_usecases.dart';
import 'features/gameSession/infrastructure/datasources/multiplayer_session_remote_data_source.dart';
import 'features/gameSession/infrastructure/realtime/multiplayer_session_realtime_impl.dart';
import 'features/gameSession/infrastructure/repositories/multiplayer_session_repository_impl.dart';
import 'features/gameSession/infrastructure/socket/multiplayer_socket_client.dart';
import 'features/gameSession/presentation/controllers/multiplayer_session_controller.dart';

import 'features/library/domain/repositories/library_repository.dart';
import 'features/library/infrastructure/repositories/library_repository_impl.dart';
import 'features/library/application/get_kahoots_use_cases.dart';
import 'features/library/application/get_kahoot_detail_use_case.dart';
import 'features/library/application/toggle_favorite_use_case.dart';
import 'features/library/presentation/providers/library_provider.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/kahoots_category_page.dart';
import 'features/library/presentation/pages/kahoot_detail_page.dart';
import 'features/groups/presentation/pages/groups_page.dart';
import 'features/user/presentation/blocs/auth_bloc.dart';
import 'features/user/presentation/user_providers.dart';
import 'features/user/presentation/pages/access_gate_page.dart';
import 'features/user/presentation/pages/profile_page.dart';
import 'features/user/presentation/widgets/session_expiry_listener.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/use_firebase.dart';
import 'core/config/api_config.dart';

import 'features/subscriptions/domain/repositories/subscription_repository.dart';
import 'features/subscriptions/application/usecases/subscribe_user_usecase.dart';
import 'features/subscriptions/application/usecases/get_subscription_status_usecase.dart';
import 'features/subscriptions/application/usecases/cancel_subscription_usecase.dart';
import 'features/subscriptions/infrastructure/repositories/simulated_subscription_repository.dart';
import 'features/subscriptions/infrastructure/repositories/subscription_repository_impl.dart';
import 'features/subscriptions/presentation/provider/subscription_provider.dart';
import 'features/subscriptions/presentation/screens/plans_screen.dart';
import 'features/subscriptions/presentation/screens/subscription_management_screen.dart';

// API base URL configurable vía --dart-define=API_BASE_URL
// Por defecto apunta al backend desplegado en Render
// API base 1: https://backcomun-mzvy.onrender.com 
// API base 2: https://quizzy-backend-1-zpvc.onrender.com
// https://bec2a32a-edf0-42b0-bfef-20509e9a5a17.mock.pstmn.io
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',

  defaultValue: 'https://quizzy-backend-1-zpvc.onrender.com',

);

// Token (UUID) usado mientras el backend mockea la verificación real.
const String apiAuthToken = String.fromEnvironment('API_AUTH_TOKEN', defaultValue: 'acde070d-8c4c-4f0d-9d8a-162843c10333');

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kUseFirebase) return;
  await Firebase.initializeApp();
  print("Mensaje recibido en segundo plano: ${message.messageId}");
}

Future<void> main() async {
  // Initialize API configuration based on environment
  _initializeApiConfig();

  // Mostrar en consola la URL base que la app está usando (útil para depuración)
  print('API_BASE_URL = $apiBaseUrl');
  print('HTTP Base URL = ${ApiConfigManager.httpBaseUrl}');
  print('WebSocket Base URL = ${ApiConfigManager.websocketBaseUrl}');

  WidgetsFlutterBinding.ensureInitialized();
  if (kUseFirebase) {
    await Firebase.initializeApp();

    // Configurar el handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  runApp(MyApp());
}

/// Initializes the API configuration based on the API_BASE_URL environment variable.
/// Supports both quizzybackend and backcomun backends.
void _initializeApiConfig() {
  // Extract domain from the full URL
  final url = Uri.parse(apiBaseUrl);
  final domain = '${url.host}${url.hasPort ? ':${url.port}' : ''}';

  // Determine backend type based on domain
  if (domain.contains('quizzy-backend')) {
    ApiConfigManager.setConfig(BackendType.quizzyBackend, domain);
  } else if (domain.contains('backcomun')) {
    ApiConfigManager.setConfig(BackendType.backcomun, domain);
  } else {
    // Default to backcomun if unrecognized
    ApiConfigManager.setConfig(BackendType.backcomun, domain);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<http.Client>(create: (_) => http.Client()),

        // Reportes: repo + casos de uso + BLoC (ChangeNotifier)
        Provider<ReportsRepository>(
          create: (context) => ReportsRepositoryImpl(
            baseUrl: ApiConfigManager.httpBaseUrl,
            client: context.read<http.Client>(),
            headersProvider: () async {
              final token = await SecureStorage.instance.read('userId');
              return {
                'Content-Type': 'application/json',
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              };
            },
          ),
        ),
        Provider<GetMyResultsUseCase>(
          create: (context) => GetMyResultsUseCase(
            context.read<ReportsRepository>(),
          ),
        ),
        Provider<GetSessionReportUseCase>(
          create: (context) => GetSessionReportUseCase(
            context.read<ReportsRepository>(),
          ),
        ),
        Provider<GetMultiplayerResultUseCase>(
          create: (context) => GetMultiplayerResultUseCase(
            context.read<ReportsRepository>(),
          ),
        ),
        Provider<GetSingleplayerResultUseCase>(
          create: (context) => GetSingleplayerResultUseCase(
            context.read<ReportsRepository>(),
          ),
        ),
        ChangeNotifierProvider<ReportsListBloc>(
          create: (context) => ReportsListBloc(
            getMyResultsUseCase: context.read<GetMyResultsUseCase>(),
          ),
        ),

        Provider<IUserDataSource>(
          create: (context) => UserRemoteDataSourceImpl(
            baseUrl: ApiConfigManager.httpBaseUrl,
            cliente: context
                .read<
                  http.Client
                >(),
          ),
        ),
        Provider<IUserRepository>(
          create: (context) => UserRepositoryImpl(
            remoteDataSource: context.read<IUserDataSource>(),
          ),
        ),
        Provider<GetUserListUseCase>(
          create: (context) =>
              GetUserListUseCase(context.read<IUserRepository>()),
        ),
        Provider<ToggleUserStatusUseCase>(
          create: (context) =>
              ToggleUserStatusUseCase(context.read<IUserRepository>()),
        ),
        Provider<DeleteUserUseCase>(
          create: (context) =>
              DeleteUserUseCase(context.read<IUserRepository>()),
        ),

        Provider<ToggleAdminRoleUseCase>(
          create: (context) => ToggleAdminRoleUseCase(
            context.read<IUserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => UserManagementProvider(
            getUserListUseCase: context.read<GetUserListUseCase>(),
            toggleUserStatusUseCase: context.read<ToggleUserStatusUseCase>(),
            deleteUserUseCase: context.read<DeleteUserUseCase>(),
            toggleAdminRoleUseCase: context.read<ToggleAdminRoleUseCase>(),
          ),
        ),

        Provider<KahootRemoteDataSource>(
          create: (context) => KahootRemoteDataSource(
            baseUrl: ApiConfigManager.httpBaseUrl,
            cliente: context.read<http.Client>(),
          ),
        ),
        Provider<ThemeRemoteDataSource>(
          create: (context) => ThemeRemoteDataSource(
            baseUrl: ApiConfigManager.httpBaseUrl,
            cliente: context.read<http.Client>(),
          ),
        ),
        Provider<IDiscoverRepository>(
          create: (context) => DiscoverRepository(
            remoteDataSource: context.read<KahootRemoteDataSource>(),
          ),
        ),
        // Se agrega ThemeRepository
        Provider<ThemeRepository>(
          create: (context) => ThemeRepository(
            remoteDataSource: context.read<ThemeRemoteDataSource>(),
          ),
        ),
        Provider<GetThemesUseCase>(
          create: (context) => GetThemesUseCase(
            context.read<ThemeRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryManagementProvider(
            repository: context.read<ThemeRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final provider = NotificationProvider(
              repository: NotificationRepository(
                dataSource: NotificationRemoteDataSource(
                  baseUrl: ApiConfigManager.httpBaseUrl,
                  client: context.read<http.Client>(),
                ),
              ),
            );
            if (kUseFirebase) {
              provider.initNotifications();
            }
            return provider;
          },
        ),
        Provider<SinglePlayerGameRepositoryImpl>(
          create: (context) => SinglePlayerGameRepositoryImpl(
            baseUrl: ApiConfigManager.httpBaseUrl,
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
        ChangeNotifierProxyProvider4<
          IDiscoverRepository,
          ThemeRepository,
          NotificationProvider,
          IUserRepository,
          DashboardProvider
        >(
          create: (context) => DashboardProvider(
            quizRepository: context.read<IDiscoverRepository>(),
            themeRepository: context.read<ThemeRepository>(),
            notificationRepository: context
                .read<NotificationProvider>()
                .repository,
            userRepository: context.read<IUserRepository>(),
          ),
          update: (context, quiz, theme, notif, user, previous) =>
              DashboardProvider(
                quizRepository: quiz,
                themeRepository: theme,
                notificationRepository: notif.repository,
                userRepository: user,
              )..loadDashboardData(),
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
              baseUrl: ApiConfigManager.httpBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
            ),
          ),
        ),
        //Estos son los proveedores para los repositorios (inyeccion de dependencias)
        // Repositorios con configuración mínima (ajusta baseUrl según tu entorno)
        Provider<QuizRepository>(
          create: (_) => QuizRepositoryImpl(baseUrl: ApiConfigManager.httpBaseUrl),
        ),
        Provider<MediaRepository>(
          create: (_) => MediaRepositoryImpl(baseUrl: ApiConfigManager.httpBaseUrl),
        ),
        Provider<StorageProviderRepository>(
          create: (_) => StorageProviderRepositoryImpl(baseUrl: ApiConfigManager.httpBaseUrl),
        ),
        Provider<MultiplayerSessionRemoteDataSource>(
          create: (context) => MultiplayerSessionRemoteDataSourceImpl(
            dio: context.read<Dio>(),
            tokenProvider: () async => apiAuthToken,
          ),
        ),
        Provider<MultiplayerSocketClient>(
          create: (_) => MultiplayerSocketClient(
            baseUrl: ApiConfigManager.websocketBaseUrl,
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
        ChangeNotifierProvider(
          create: (context) => QuizEditorBloc(
            context.read<QuizRepository>(),
            getThemesUseCase: context.read<GetThemesUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MediaEditorBloc(
            mediaRepository: context.read<MediaRepository>(),
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
        Provider<LibraryRepository>(
          create: (context) => LibraryRepositoryImpl(
            baseUrl: ApiConfigManager.httpBaseUrl,
            client: context.read<http.Client>(),
          ),
        ),
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
        ChangeNotifierProvider<LibraryProvider>(
          create: (context) => LibraryProvider(
            getCreated: context.read<GetCreatedKahootsUseCase>(),
            getFavorite: context.read<GetFavoriteKahootsUseCase>(),
            getInProgress: context.read<GetInProgressKahootsUseCase>(),
            getCompleted: context.read<GetCompletedKahootsUseCase>(),
            toggleFavorite: context.read<ToggleFavoriteUseCase>(),
          ),
        ),
        //Epica Suscripción
        Provider<ISubscriptionRepository>(
          create: (_) => SimulatedSubscriptionRepository(),
        ),
        Provider<SubscribeUserUseCase>(
          create: (context) =>
              SubscribeUserUseCase(context.read<ISubscriptionRepository>()),
        ),
        Provider<GetSubscriptionStatusUseCase>(
          create: (context) => GetSubscriptionStatusUseCase(
            context.read<ISubscriptionRepository>(),
          ),
        ),
        Provider<CancelSubscriptionUseCase>(
          create: (context) => CancelSubscriptionUseCase(
            context.read<ISubscriptionRepository>(),
          ),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (context) => SubscriptionProvider(
            subscribeUserUseCase: context.read<SubscribeUserUseCase>(),
            getSubscriptionStatusUseCase: context
                .read<GetSubscriptionStatusUseCase>(),
            cancelSubscriptionUseCase: context
                .read<CancelSubscriptionUseCase>(),
          ),
        ),
      ],

      child: UserProviders(
        child: Builder(
          builder: (context) {
            return SessionExpiryListener(
              child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Trivvy',
              // Esto viene de la rama epica9y11 para que funcionen los SnackBar de notificaciones
              scaffoldMessengerKey: context
                  .read<NotificationProvider>()
                  .messengerKey,
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
              ),
              // Decidimos la ruta inicial (AccessGatePage suele ser para Login/Onboarding)
              initialRoute: '/',
              routes: {
                '/': (context) => const AccessGatePage(),
                '/dashboard': (context) => DashboardPage(),
                '/welcome': (context) => const AccessGatePage(),
                '/profile': (context) {
                  // Usamos la lógica de la rama principal para el perfil
                  final auth = Provider.of<AuthBloc>(context, listen: false);
                  final user = auth.currentUser;
                  if (user == null) return const AccessGatePage();
                  return ProfilePage(user: user);
                },
                '/create': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  Quiz? template;
                  bool explicitClear = false;
                  if (args is Quiz) template = args;
                  if (args is Map && args['clear'] == true)
                    explicitClear = true;
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
                '/discover': (context) => const DiscoverScreen(),
                '/library': (context) => LibraryPage(),
                '/groups': (context) => const GroupsPage(),
                '/kahoots-category': (context) => const KahootsCategoryPage(),
                '/kahoot-detail': (context) => const KahootDetailPage(),
                '/discovery-detail': (context) => const DiscoveryDetailPage(),
                '/subscriptions': (context) => const PlansScreen(),
                '/subscription-management': (context) =>
                    const SubscriptionManagementScreen(),
                '/admin': (context) => const AdminPage(),
                '/admin/users': (context) => const UserManagementPage(),
                '/admin/notifications': (context) =>
                    const NotificationAdminPage(),
                '/admin/dashboard': (context) => const AdminDashboardPage(),
                '/notifications-history': (context) =>
                    const NotificationsHistoryPage(),
              },
              ),
            );
          },
        ),
      ),
    );
  }
}
