import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../Provider/NotificationProvider.dart';


class NotificationsHistoryPage extends StatefulWidget {
  const NotificationsHistoryPage({super.key});

  @override
  State<NotificationsHistoryPage> createState() => _NotificationsHistoryPageState();
}

class _NotificationsHistoryPageState extends State<NotificationsHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text('Mi Historial'),
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.greenAccent),
            tooltip: 'Activar Notificaciones',
            onPressed: () => provider.enableNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_off, color: Colors.redAccent),
            tooltip: 'Desactivar Notificaciones',
            onPressed: () => provider.disableNotifications(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de la lista
          Expanded(
            child: provider.history.isEmpty
                ? const Center(
              child: Text(
                'No tienes notificaciones aún.',
                style: TextStyle(color: AppColor.secundary),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final notification = provider.history[index];
                return Card(
                  color: notification.isRead ? AppColor.background : AppColor.card,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColor.accent.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColor.secundary,
                      child: Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      notification.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tipo: ${notification.type}',
                        style: TextStyle(color: AppColor.secundary.withOpacity(0.8)),
                      ),
                    ),
                    onTap: () => context.read<NotificationProvider>().markAsRead(notification.id),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${notification.createdAt.day}/${notification.createdAt.month}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.secundary,
                              fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColor.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- BOTÓN DE DEBUG AL FONDO ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Hace que el botón ocupe el ancho disponible
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<NotificationProvider>().printCurrentToken();
                },
                icon: const Icon(Icons.key),
                label: const Text('Obtener FCM Token (Debug)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}