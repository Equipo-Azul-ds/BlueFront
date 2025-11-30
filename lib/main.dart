import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import 'features/media/presentation/blocs/media_editor_bloc.dart';
import 'common_pages/dashboard_page.dart';
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
import 'core/constants/colors.dart';
import 'features/kahoot/domain/entities/Quiz.dart';

// API base URL configurable vía --dart-define=API_BASE_URL
// Por defecto apunta al backend desplegado en Railway
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://backcomun-production.up.railway.app');


void main() {
  // Mostrar en consola la URL base que la app está usando (útil para depuración)
  print('API_BASE_URL = $apiBaseUrl');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //Estos son los proveedores para los repositorios (inyeccion de dependencias)
        // Repositorios con configuración mínima (ajusta baseUrl según tu entorno)
        Provider<QuizRepository>(create: (_)=> QuizRepositoryImpl(baseUrl: apiBaseUrl)),
        Provider<MediaRepository>(create: (_)=> MediaRepositoryImpl(baseUrl: apiBaseUrl)),
        Provider<StorageProviderRepository>(create: (_)=> StorageProviderRepositoryImpl(baseUrl: apiBaseUrl)),
        // Blocs / ChangeNotifiers
        ChangeNotifierProvider(create: (context)=> QuizEditorBloc(context.read<QuizRepository>())),
        ChangeNotifierProvider(create: (context)=> MediaEditorBloc(
          uploadUseCase: UploadMediaUseCase(mediaRepository: context.read<MediaRepository>()),
          getUseCase: GetMediaUseCase(mediaRepository: context.read<MediaRepository>(), storageProvider: context.read<StorageProviderRepository>()),
          deleteUseCase: DeleteMediaUseCase(mediaRepository: context.read<MediaRepository>(), storageProvider: context.read<StorageProviderRepository>()),
        )),
      ],
      child: MaterialApp(
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
          ),
          initialRoute: '/dashboard',
          routes:{
            '/dashboard': (context)=> DashboardPage(),
            // /create ahora acepta opcionalmente una `Quiz` como argumento (plantilla)
            '/create': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              Quiz? template;
              if (args is Quiz) template = args;
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

