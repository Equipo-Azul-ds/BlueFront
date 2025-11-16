import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
import 'package:provider/provider.dart';
import '../blocs/kahoot_editor_bloc.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/kahoot.dart';
import '../widgets/kahoot_card.dart';
import '../widgets/staggered_grid.dart';

class DashboardPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    final kahootBloc = Provider.of<KahootEditorBloc>(context);

    //Datos simualdos que posteriormente se reemplazaran con la api
      final recentKahoots = [
        Kahoot(
          id: '1',
           title: 'Arquitectura Hexagonal',
            visibility: 'publico', 
            status: 'publico', 
            themes: [], 
            authorId: 'Massiel', 
            createdAt: DateTime.now()),
        Kahoot(
          id: '2', 
          title: 'Desarrollo de software', 
          visibility: 'publico',
          status: 'publico', 
          themes: [], 
          authorId: 'Jose', 
          createdAt: DateTime.now()),
      ];

      final recommendedKahoots = [
        Kahoot(
          id: '3', 
          title: 'Seguimos en prueba', 
          visibility: 'publico', 
          status: 'publico', 
          themes: [], 
          authorId: 'Massiel', 
          createdAt: DateTime.now()),
        Kahoot(
          id: '4', 
          title: 'hOLA ESTO ES UNA PRUEBA', 
          visibility: 'publico', 
          status: 'publico', 
          themes: [], 
          authorId: 'Jose', 
          createdAt: DateTime.now()),
      ];

      final TextEditingController pinController = TextEditingController();

    return Scaffold(
    backgroundColor: AppColor.background,
    body: SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20),
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
                  SizedBox(height: 24), // Baja aquí un poco el saludo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, Jugador!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Listo para jugar hoy?',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Tu input PIN y botón
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                        SizedBox(height: 12),
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
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 6,
                            shadowColor: Colors.amber.shade300,
                          ),
                          child: Text(
                            'Unirse al juego',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recientes',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final kahoot = recentKahoots[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text('Hace 2 días • 80% correcto',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                  );
                },
                childCount: recentKahoots.length,
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Recomendado para ti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: staggered.SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childCount: recommendedKahoots.length,
              itemBuilder: (context, index) {
                final kahoot = recommendedKahoots[index];
                return KahootCard(
                  kahoot: kahoot,
                  onTap: () => Navigator.pushNamed(context, '/gameDetail',
                      arguments: kahoot.id),
                );
              },
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/create');
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
