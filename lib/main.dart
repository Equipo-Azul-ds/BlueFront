import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/blocs/kahoot_editor_bloc.dart';
import 'presentation/blocs/slide_editor_bloc.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/kahoot_editor_page.dart';
import 'presentation/pages/slide_editor_page.dart';
import 'presentation/pages/template_selector_page.dart';
import 'infraestructure/repositories/kahoot_repository_impl.dart';
import 'infraestructure/repositories/slide_repository_impl.dart';


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
            //'/discover': (context) => DiscoverPage(), // Agregar si existe
            //'/library': (context) => LibraryPage(), // Agregar si existe
          },
          home: DashboardPage(),//Pagina inicial
      ),
    );
  }
}

