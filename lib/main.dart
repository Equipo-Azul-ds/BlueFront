import 'package:Trivvy/features/Administrador/Presentacion/pages/NotificationAdminPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
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
import 'features/discovery/presentation/pages/discover_page.dart';

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
import 'features/groups/presentation/pages/groups_page.dart';
import 'features/user/presentation/blocs/auth_bloc.dart';
import 'features/user/presentation/user_providers.dart';
import 'features/user/presentation/pages/access_gate_page.dart';
import 'features/user/presentation/pages/profile_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
// API base 1: 'https://backcomun-gc5j.onrender.com'
// API base 2: https://quizzy-backend-0wh2.onrender.com/api
// https://bec2a32a-edf0-42b0-bfef-20509e9a5a17.mock.pstmn.io
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',

  defaultValue: 'https://backcomun-gc5j.onrender.com',
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensaje recibido en segundo plano: ${message.messageId}");
}

Future<void> main() async {
  // Mostrar en consola la URL base que la app está usando (útil para depuración)
  print('API_BASE_URL = $apiBaseUrl');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configurar el handler de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<http.Client>(create: (_) => http.Client()),

        Provider<IUserDataSource>(
          create: (context) => UserRemoteDataSourceImpl(
            // Usa 'context' aquí
            baseUrl: apiBaseUrl,
            cliente: context
                .read<
                  http.Client
                >(), // Ahora buscará al Provider<http.Client> de arriba
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
            baseUrl: apiBaseUrl,
            cliente: context.read<http.Client>(),
          ),
        ),
        Provider<ThemeRemoteDataSource>(
          create: (context) => ThemeRemoteDataSource(
            baseUrl: apiBaseUrl,
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
        ChangeNotifierProvider(
          create: (context) => CategoryManagementProvider(
            repository: context.read<ThemeRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            repository: NotificationRepository(
              dataSource: NotificationRemoteDataSource(
                baseUrl: apiBaseUrl,
                client: context.read<http.Client>(),
              ),
            ),
          )..initNotifications(),
        ),
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
        baseUrl: apiBaseUrl,
        child: Builder(
          builder: (context) {
            return MaterialApp(
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
            );
          },
        ),
      ),
    );
  }
}
