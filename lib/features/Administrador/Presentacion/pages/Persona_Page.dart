import 'package:flutter/material.dart';

class PersonaPage extends StatelessWidget {
  const PersonaPage({super.key});

  // Ruta a la que esta página navegará
  static const String adminRoute = '/admin';

  void _navigateToAdmin(BuildContext context) {
    // Usamos pushNamed para ir a la nueva página de administrador
    Navigator.of(context).pushNamed(adminRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Consistencia: Aunque no se use, se recupera el ID de los argumentos
    // para mantener el patrón de navegación que establecimos.
    final String? personaId = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Persona'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (personaId != null)
              Text('ID de Persona (Recibido): $personaId'),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => _navigateToAdmin(context),
              child: const Text('Ir a Página de Administrador'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}