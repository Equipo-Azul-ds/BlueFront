import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'features/discovery/domain/Repositories/IDiscoverRepository.dart';
import 'features/discovery/infraestructure/dataSource/ThemeRemoteDataSource.dart';
import 'features/discovery/infraestructure/dataSource/kahootRemoteDataSource.dart';
import 'features/discovery/infraestructure/repositories/DiscoverRepository.dart';
import 'features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'features/discovery/presentation/pages/discover_page.dart';
import 'features/kahoot/presentation/blocs/kahoot_editor_bloc.dart';
import 'features/slide/presentation/blocs/slide_editor_bloc.dart';
import 'common_pages/dashboard_page.dart';
import 'features/kahoot/presentation/pages/kahoot_editor_page.dart';
import 'features/slide/presentation/pages/slide_editor_page.dart';
import 'common_pages/template_selector_page.dart';
import 'features/kahoot/infrastructure/repositories/kahoot_repository_impl.dart';
import 'features/slide/infrastructure/repositories/slide_repository_impl.dart';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://backcomun-production.up.railway.app');
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //Estos son los proveedores para los repositorios (inyeccion de dependencias)
        Provider<KahootRepositoryImpl>(create: (_)=> KahootRepositoryImpl()), //Aqui lo que hacemos es registrar el repositorio de Kahoot
        Provider<SlideRepositoryImpl>(create: (_)=> SlideRepositoryImpl()),  //Aqui lo que hacemos es registrar el repositorio de Slide
        Provider<ThemeRemoteDataSource>(
          create: (context) => ThemeRemoteDataSource(
          baseUrl: apiBaseUrl,
          cliente: context.read<http.Client>(),
          ),
        ),
        Provider<ThemeRepository>(
          create: (context) => ThemeRepository(
          remoteDataSource: context.read<ThemeRemoteDataSource>(),
          ),
        ),
        Provider<KahootRemoteDataSource>(
          create: (context) => KahootRemoteDataSource(
          baseUrl: apiBaseUrl,
          cliente: context.read<http.Client>(),
          ),
        ),
        Provider<IDiscoverRepository>(
          create: (context) => DiscoverRepository(
          remoteDataSource: context.read<KahootRemoteDataSource>(),
          ),
        ),
        //Blocs para el estado
      ChangeNotifierProvider(create: (context)=> KahootEditorBloc(context.read<KahootRepositoryImpl>())), //Aqui registramos el Bloc de Kahoot
      ChangeNotifierProvider(create: (context)=> SlideEditorBloc(context.read<SlideRepositoryImpl>())),
      ],

      child: MaterialApp(
          title: 'Trivvy',
          theme: ThemeData(primarySwatch: Colors.blue), //tema personalizado
          initialRoute: '/dashboard',
          routes:{
            '/dashboard': (context)=> DashboardPage(),
            '/create': (context)=> KahootEditorPage(),
            '/slideEditor': (context) => SlideEditorPage(slideId: ModalRoute.of(context)!.settings.arguments as String),
            '/templateSelector': (context) => TemplateSelectorPage(),
            //Comentoados por ahora
            //'/joinLobby': (context) => JoinLobbyPage(), // Agregar si existe
            //'/gameDetail': (context) => GameDetailPage(), // Agregar si existe
            '/discover': (context) => DiscoverScreen(), // Agregar si existe
            //'/library': (context) => LibraryPage(), // Agregar si existe
          },
          home: DashboardPage(),//Pagina inicial
      ),
    );
  }
}

