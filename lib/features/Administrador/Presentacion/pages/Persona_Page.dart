import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../Notifications/Presentacion/Provider/NotificationProvider.dart';

class PersonaPage extends StatelessWidget {
  const PersonaPage({super.key});

  static const String adminRoute = '/admin';
  static const String notificationsHistoryRoute = '/notifications-history';

  @override
  Widget build(BuildContext context) {
    final String? personaId = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Persona')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (personaId != null) Text('ID de Persona: $personaId'),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, notificationsHistoryRoute),
              icon: const Icon(Icons.history),
              label: const Text('Historial de Notificaciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700, // Color distinto para diferenciar
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(adminRoute),
              child: const Text('Ir a Página de Administrador'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationProvider>().simulateIncomingNotification();
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Simular Notificación Push'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error, // Rojo para indicar que es de prueba
                foregroundColor: Colors.white,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationProvider>().printCurrentToken();
              },
              icon: const Icon(Icons.key),
              label: const Text('Obtener FCM Token (Debug)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}