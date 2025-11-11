import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/blocs/kahoot_editor_bloc.dart';
import 'presentation/blocs/slide_editor_bloc.dart';
import 'presentation/pages/dashboard_page.dart';
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
      ChangeNotifierProvider(create: (context)=> SlideEditorBloc(context.read<SlideRepositorytImpl>())), //Aqui registramos el Bloc de Slide
      ],
      child: MateriaLApp(
          title: 'Trivvy',
          theme: ThemeData(primarySwatch: Colors.blue), //tema personalizado
          home: DashboardPage(),//Pagina inicial
      ),
    );
  }
}

