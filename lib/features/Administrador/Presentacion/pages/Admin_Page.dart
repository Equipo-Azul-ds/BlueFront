import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  // Widget auxiliar para los botones de la dashboard de administración
  Widget _buildAdminButton(
      BuildContext context,
      String title,
      IconData icon,
      String routeName,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navegación real a la ruta especificada
          Navigator.pushNamed(context, routeName);
        },
        icon: Icon(icon, color: Colors.white, size: 30),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona una opción de gestión:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 30),

            _buildAdminButton(
              context,
              'Dashboard (Estadísticas)',
              Icons.dashboard,
              '/admin/dashboard',
            ),
            _buildAdminButton(
              context,
              'Gestión de Usuarios',
              Icons.people_alt,
              '/admin/users', // Esta ruta ya coincide con la de main.dart
            ),
            _buildAdminButton(
              context,
              'Gestión de Categorias',
              Icons.quiz,
              '/admin/categories',
            ),
            _buildAdminButton(
              context,
              'Gestión de Notificaciones',
              Icons.notifications_active,
              '/admin/notifications',
            ),
          ],
        ),
      ),
    );
  }
}