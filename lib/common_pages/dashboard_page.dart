import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
// imports removed: provider and bloc not used in this page
import '../core/constants/colors.dart';
import '../features/kahoot/domain/entities/kahoot.dart';
import '../common_widgets/kahoot_card.dart';
// removed unused staggered_grid import

class DashboardPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    // Obtener el bloc si es necesario en el futuro

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
                        SizedBox(height: headerHeight * 0.06), // Responsive height based on header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hola, Jugador!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth * 0.07, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Listo para jugar hoy?',
                                      style: TextStyle(color: Colors.white70, fontSize: constraints.maxWidth * 0.04)),
                                ],
                              ),
                            ),
                            // Limitar el radio del avatar para evitar tamaños extremos
                            CircleAvatar(
                              radius: (constraints.maxWidth * 0.06).clamp(18.0, 40.0),
                              backgroundImage: AssetImage('assets/images/logo.png'),
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
                          arguments: kahoot.id),
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
