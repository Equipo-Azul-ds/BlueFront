import 'package:flutter/material.dart';
import '../core/constants/colors.dart';




class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (currentIndex != 0) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
            break;
          case 1:
            if (currentIndex != 1) {
              Navigator.pushReplacementNamed(context, '/discover');
            }
            break;
          case 2:
            break;
          case 3:
            if (currentIndex != 3) {
              Navigator.pushReplacementNamed(context, '/library');
            }
            break;
          case 4:
            if (currentIndex != 4) {
              Navigator.pushReplacementNamed(context, '/profile');
            }
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Descubre'),
        BottomNavigationBarItem(icon: Icon(null), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}