import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Notifications/Presentacion/Provider/NotificationProvider.dart';

class NotificationAdminPage extends StatefulWidget {
  const NotificationAdminPage({super.key});

  @override
  State<NotificationAdminPage> createState() => _NotificationAdminPageState();
}

class _NotificationAdminPageState extends State<NotificationAdminPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // Parámetros para los filtros
  bool _toAdmins = false;
  bool _toRegularUsers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargamos el historial de envíos administrativos al entrar
      context.read<NotificationProvider>().loadAdminHistory();
    });
  }

  void _submit(NotificationProvider provider) async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa el título y el mensaje')),
      );
      return;
    }

    if (!_toAdmins && !_toRegularUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un destinatario')),
      );
      return;
    }

    await provider.sendMassiveNotification(
      title: _titleController.text,
      message: _messageController.text,
      toAdmins: _toAdmins,
      toRegularUsers: _toRegularUsers,
    );

    if (!provider.isSending) {
      _titleController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Notificaciones'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.send), text: 'Enviar Nueva'),
              Tab(icon: Icon(Icons.history), text: 'Historial de Envíos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: FORMULARIO DE ENVÍO
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nueva Notificación Masiva",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la Notificación',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Mantenimiento de Servidores',
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Cuerpo del Mensaje (Correo)',
                      border: OutlineInputBorder(),
                      hintText: 'Escribe aquí el contenido del correo...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Destinatarios:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text("Administradores"),
                    value: _toAdmins,
                    onChanged: (val) => setState(() => _toAdmins = val),
                  ),
                  SwitchListTile(
                    title: const Text("Usuarios Regulares"),
                    value: _toRegularUsers,
                    onChanged: (val) => setState(() => _toRegularUsers = val),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSending ? null : () => _submit(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: provider.isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Icon(Icons.send_sharp),
                      label: Text(provider.isSending ? 'Enviando...' : 'Enviar Notificación Masiva'),
                    ),
                  )
                ],
              ),
            ),

            // PESTAÑA 2: HISTORIAL ADMINISTRATIVO
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: provider.adminHistory.length,
              itemBuilder: (context, index) {
                final notification = provider.adminHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.mail)),
                    title: Text(notification.message),
                    subtitle: Text("Enviado el: ${notification.createdAt.toString().split(' ')[0]}"),
                    isThreeLine: true,
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