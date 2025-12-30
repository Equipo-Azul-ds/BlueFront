import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Notifications/Presentacion/Provider/NotificationProvider.dart';

class NotificationAdminPage extends StatefulWidget {
  const NotificationAdminPage({super.key});

  @override
  State<NotificationAdminPage> createState() => _NotificationAdminPageState();
}

class _NotificationAdminPageState extends State<NotificationAdminPage> {
  final _bodyController = TextEditingController();

  void _submit(NotificationProvider provider) async {
    if ( _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un mensaje')),
      );
      return;
    }

    final success = await provider.sendAdminNotification(
      _bodyController.text,
    );

    if (success && mounted) {
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación enviada con éxito (Simulado)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Notificaciones'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.send), text: "Enviar"),
              Tab(icon: Icon(Icons.history), text: "Historial"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje (Cuerpo)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSending ? null : () => _submit(provider),
                      icon: provider.isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.campaign),
                      label: Text(provider.isSending ? 'Enviando...' : 'Enviar a todos los usuarios'),
                    ),
                  )
                ],
              ),
            ),
            ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final notification = provider.history[index];
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  title: Text(notification.type), // Mostrará 'admin_notification'
                  subtitle: Text(notification.message), // El texto que escribió el admin
                  trailing: Text(
                    "${notification.createdAt.day}/${notification.createdAt.month}",
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}