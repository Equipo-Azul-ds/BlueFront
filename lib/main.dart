import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import 'features/media/presentation/blocs/media_editor_bloc.dart';
import 'common_pages/dashboard_page.dart';
import 'features/kahoot/presentation/pages/quiz_editor_page.dart';
import 'features/media/presentation/pages/slide_editor_page.dart';
import 'common_pages/template_selector_page.dart';
import 'features/kahoot/infrastructure/repositories/kahoot_repository_impl.dart';
import 'features/media/infrastructure/repositories/slide_repository_impl.dart';
import 'core/constants/colors.dart';


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

