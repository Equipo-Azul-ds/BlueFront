import 'package:flutter/material.dart';
import 'main_bottom_nav_bar.dart';

String _getRouteName(int index) {
  switch (index) {
    case 0:
      return '/dashboard';
    case 1:
      return '/discover';
    case 2:
      return '/create';
    case 3:
      return '/library';
    case 4:
      return '/profile';
    default:
      return '/dashboard';
  }
}

void handleSubpageTap(int tappedIndex, BuildContext context, int baseIndex) {
  // Obtener la ruta de destino (si no es el FAB)
  final String targetRoute = _getRouteName(tappedIndex);

  if (tappedIndex == 2) {
    Navigator.pushNamed(context, targetRoute);
    return;
  }

  Navigator.popUntil(context, ModalRoute.withName('/dashboard'));

  if (targetRoute != '/dashboard') {
    Navigator.pushReplacementNamed(context, targetRoute);
  }
  return;
}

class SubpageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int baseIndex;

  const SubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.baseIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      floatingActionButton: FloatingActionButton(
        onPressed: () => handleSubpageTap(2, context, baseIndex),
        backgroundColor: Colors.amber.shade400,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: MainBottomNavBar(
        currentIndex: baseIndex,
        onTap: (index) => handleSubpageTap(index, context, baseIndex),
      ),

      body: body,
    );
  }
}
