import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'
    as staggered;
import '../core/constants/colors.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../common_widgets/main_bottom_nav_bar.dart';

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final recentKahoots = [
      {'id': '1', 'title': 'Arquitectura Hexagonal'},
      {'id': '2', 'title': 'Desarrollo de software'},
    ];
    final recommendedKahoots = [
      {'id': '3', 'title': 'Seguimos en prueba'},
      {'id': '4', 'title': 'hOLA ESTO ES UNA PRUEBA'},
    ];
    final TextEditingController pinController = TextEditingController();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        double headerHeight = min(
          constraints.maxHeight * 0.45,
          screenSize.height * 0.45,
        );
        headerHeight = max(headerHeight, screenSize.height * 0.22);

        return CustomScrollView(
          slivers: [
            // ... (Todo el contenido del header, PIN Input, Recientes y Recomendados) ...
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
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: headerHeight * 0.06),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: (constraints.maxWidth * 0.12).clamp(
                              40.0,
                              80.0,
                            ),
                            height: (constraints.maxWidth * 0.12).clamp(
                              40.0,
                              80.0,
                            ),
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: constraints.maxWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Hola, Jugador!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: constraints.maxWidth * 0.07,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Listo para jugar hoy?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: constraints.maxWidth * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: headerHeight * 0.04),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04,
                          vertical: screenSize.height * 0.03,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth * 0.05,
                                  vertical: screenSize.height * 0.015,
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.015),
                            ElevatedButton(
                              onPressed: () {
                                final pin = pinController.text.trim();
                                if (pin.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Por favor ingresa un PIN valido para poder jugar',
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/joinLobby',
                                    arguments: pin,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade400,
                                minimumSize: Size(
                                  double.infinity,
                                  max(48.0, screenSize.height * 0.06),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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

            // Sección Recientes
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth * 0.045,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver todo',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final kahoot = recentKahoots[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.04,
                      vertical: screenSize.height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: AppColor.primary, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kahoot['title']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth * 0.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hace 2 días • 80% correcto',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.03,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: recentKahoots.length),
              ),
            ),

            // Sección Recomendados
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.0125,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Recomendado para ti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: constraints.maxWidth * 0.045,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: screenSize.height * 0.0125,
              ),
              sliver: staggered.SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: max(8.0, screenSize.height * 0.01),
                crossAxisSpacing: constraints.maxWidth * 0.02,
                childCount: recommendedKahoots.length,
                itemBuilder: (context, index) {
                  final kahoot = recommendedKahoots[index];
                  return ListTile(
                    title: Text(kahoot['title']!),
                    subtitle: const Text('Recomendado'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/gameDetail',
                      arguments: kahoot['id'],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: min(screenSize.height * 0.06, 120)),
            ),
          ],
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePageContent(), // 0: Inicio
    Scaffold(
      body: Center(child: Text('Descubre Page')),
    ), // 1: Descubre (Placeholder)
    SizedBox.shrink(), // 2: Placeholder for FAB
    LibraryPage(), // 3: Biblioteca (Tu Épica 7)
    Scaffold(
      body: Center(child: Text('Perfil Page')),
    ), // 4: Perfil (Placeholder)
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // El índice 2 es el espacio del FAB, navega a '/create'
      Navigator.pushNamed(context, '/create');
      return;
    }
    // Lógica para cambiar de pestaña en el IndexedStack
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create');
        },
        backgroundColor: Colors.amber.shade400,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // USANDO EL WIDGET REUTILIZABLE
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
