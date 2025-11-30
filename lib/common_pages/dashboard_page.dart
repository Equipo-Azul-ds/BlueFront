import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/presentation/blocs/quiz_editor_bloc.dart';
import '../features/kahoot/domain/entities/Quiz.dart';
import '../common_widgets/kahoot_card.dart';

class DashboardPage extends StatefulWidget{
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loadingUserQuizzes = false;

  @override
  void initState() {
    super.initState();
    // Load user quizzes on enter (uses a placeholder author id)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizBloc = Provider.of<QuizEditorBloc>(context, listen: false);
      if (quizBloc.userQuizzes == null) {
        // Only call backend if we have a valid authorId (UUID v4). Otherwise skip to avoid
        // server errors when a placeholder is used.
        final authorIdCandidate = quizBloc.currentQuiz?.authorId ?? '';
        final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
        if (uuidV4.hasMatch(authorIdCandidate)) {
          setState(() => _loadingUserQuizzes = true);
          try {
            await quizBloc.loadUserQuizzes(authorIdCandidate);
          } catch (_) {}
          if (mounted) setState(() => _loadingUserQuizzes = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context){
    // Obtener el bloc si es necesario en el futuro
    final quizBloc = Provider.of<QuizEditorBloc>(context);
    // If navigator passed a created quiz as an argument, insert it into userQuizzes so
    // it is visible immediately without calling the backend.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Quiz) {
      quizBloc.userQuizzes ??= [];
      final exists = quizBloc.userQuizzes!.any((q) => q.quizId == args.quizId && q.title == args.title);
      if (!exists) {
        quizBloc.userQuizzes!.insert(0, args);
      }
    }

    //Datos simualdos que posteriormente se reemplazaran con la api
      final recentKahoots = [
        Quiz(
          quizId: '1',
          authorId: 'Massiel',
          title: 'Arquitectura Hexagonal',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
        Quiz(
          quizId: '2',
          authorId: 'Jose',
          title: 'Desarrollo de software',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
      ];

      final recommendedKahoots = [
        Quiz(
          quizId: '3',
          authorId: 'Massiel',
          title: 'Seguimos en prueba',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
        Quiz(
          quizId: '4',
          authorId: 'Jose',
          title: 'hOLA ESTO ES UNA PRUEBA',
          description: '',
          visibility: 'public',
          themeId: '',
          createdAt: DateTime.now(),
          questions: [],
        ),
      ];

      final TextEditingController pinController = TextEditingController();

    

    return Scaffold(
    backgroundColor: AppColor.background,
    body: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          // Limitar la altura del header para evitar tamaños enormes al hacer overscroll
          double headerHeight = min(constraints.maxHeight * 0.45, screenSize.height * 0.45);
          // Asegurar un minimo para que el header no colapse en pantallas pequeñas
          headerHeight = max(headerHeight, screenSize.height * 0.22);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: headerHeight,
                  child: Container(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.05), 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColor.primary, AppColor.secundary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),

                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: headerHeight * 0.06),
                        // Colocar el logo arriba del saludo y alineado a la izquierda
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo a la izquierda, arriba del texto
                            Image.asset(
                              'assets/images/logo.png',
                              width: (constraints.maxWidth * 0.12).clamp(40.0, 80.0),
                              height: (constraints.maxWidth * 0.12).clamp(40.0, 80.0),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: constraints.maxWidth * 0.04),
                            // Textos (Hola, Jugador! y subtitulo)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Hola, Jugador!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth * 0.07,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Listo para jugar hoy?',
                                      style: TextStyle(color: Colors.white70, fontSize: constraints.maxWidth * 0.04)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: headerHeight * 0.04),
                        // Tu input PIN y botón
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: screenSize.height * 0.03),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: pinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa PIN de juego',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                    contentPadding:
                                      EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.015),
                                ),
                              ),
                                  SizedBox(height: screenSize.height * 0.015),
                              ElevatedButton(
                                onPressed: () {
                                  final pin = pinController.text.trim();
                                  if (pin.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Por favor ingresa un PIN valido para poder jugar'),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushNamed(context, '/joinLobby',
                                        arguments: pin);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade400,
                                  minimumSize: Size(double.infinity, max(48.0, screenSize.height * 0.06)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  elevation: 6,
                                  shadowColor: Colors.amber.shade300,
                                ),
                                child: Text(
                                  'Unirse al juego',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: constraints.maxWidth * 0.04,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                      ],
                    ),
                  ),
                ),
              ),

              // Tus Quizzes section (top-level sliver)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.01),
                sliver: SliverToBoxAdapter(
                  child: Builder(builder: (ctx) {
                    final userQuizzes = quizBloc.userQuizzes ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tus Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: constraints.maxWidth * 0.045)),
                        SizedBox(height: 8),
                        if (_loadingUserQuizzes) Center(child: CircularProgressIndicator()),
                        if (!_loadingUserQuizzes && userQuizzes.isEmpty)
                          Text('No tienes quizzes aún. Crea uno con el botón +', style: TextStyle(color: Colors.grey[700])),
                        if (userQuizzes.isNotEmpty)
                          Column(
                            children: userQuizzes.map((q) => Container(
                              margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                              padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: screenSize.height * 0.015),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border(left: BorderSide(color: AppColor.primary, width: 4)),
                              ),
                              child: Row(
                                children: [
                                  // Cover image if available
                                  Container(
                                    width: constraints.maxWidth * 0.18,
                                    height: constraints.maxWidth * 0.12,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                                    clipBehavior: Clip.hardEdge,
                                    child: q.coverImageUrl != null && q.coverImageUrl!.startsWith('http')
                                      ? Image.network(q.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image))
                                      : Center(child: Icon(Icons.image, color: Colors.grey[600])),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(q.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: constraints.maxWidth * 0.04)),
                                    SizedBox(height: 4),
                                    Text('Creado ${q.createdAt.toLocal().toString().split(' ').first} • ${q.questions.length} preguntas', style: TextStyle(color: Colors.grey[700], fontSize: constraints.maxWidth * 0.03)),
                                  ])),
                                  IconButton(onPressed: () => Navigator.pushNamed(context, '/create', arguments: q), icon: Icon(Icons.edit)),
                                ],
                              ),
                            )).toList(),
                          ),
                      ],
                    );
                  }),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recientes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth * 0.045
                          )),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Ver todo',
                          style: TextStyle(
                              color: AppColor.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final kahoot = recentKahoots[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04, vertical: screenSize.height * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: AppColor.primary, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kahoot.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: constraints.maxWidth * 0.04
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Hace 2 días • 80% correcto',
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.03,
                                  color: Colors.grey[700]
                                )),
                          ],
                        ),
                      );
                    },
                    childCount: recentKahoots.length,
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.0125),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recomendado para ti',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: constraints.maxWidth * 0.045
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: screenSize.height * 0.0125),
                sliver: staggered.SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                  crossAxisSpacing: constraints.maxWidth * 0.02,
                  childCount: recommendedKahoots.length,
                  itemBuilder: (context, index) {
                    final kahoot = recommendedKahoots[index];
                    return KahootCard(
                      kahoot: kahoot,
                        onTap: () => Navigator.pushNamed(context, '/gameDetail',
                          arguments: kahoot.quizId),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: min(screenSize.height * 0.06, 120))),
            ],
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        // Abrir selector de plantillas; si el usuario elige una, navegar al editor con la plantilla
        final selected = await Navigator.pushNamed(context, '/templateSelector');
        if (selected != null && selected is Quiz) {
          Navigator.pushNamed(context, '/create', arguments: selected);
        } else {
          Navigator.pushNamed(context, '/create');
        }
      },
      backgroundColor: Colors.amber.shade400,
      child: Icon(Icons.add),
      elevation: 6,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: _builBottonNav(context, 0),
  );
  }

  Widget _builBottonNav(BuildContext context, int currentIndex){
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index){
        switch(index){
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/discover');
            break;
          case 2:
            //El espcio entre botones centrales (FAB) no hace nada
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/library');
            break;
          case 4: 
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: Colors.grey,
      items: const[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Descubre'),
        BottomNavigationBarItem(icon: Icon(null), label: ''), //Espacio para FAB
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
