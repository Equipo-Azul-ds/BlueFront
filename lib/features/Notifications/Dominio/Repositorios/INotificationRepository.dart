import '../Entidades/NotificationEntiry.dart';

abstract class INotificationRepository {
  // --- Gestión de Dispositivo ---
  Future<void> registerToken(String token, String deviceType);
  Future<void> unregisterToken(String token);

  // --- Notificaciones Personales (Usuario) ---
  Future<List<NotificationEntity>> getHistory();
  Future<NotificationEntity> markAsRead(String id);

  // --- Notificaciones Administrativas (Backoffice) ---


  Future<void> sendMassNotification({
    required String title,
    required String message,
    required bool toAdmins,
    required bool toRegularUsers,
  });


  Future<List<NotificationEntity>> getAdminNotificationHistory({
    int limit = 20,
    int page = 1,
    String? userId,
  });
}