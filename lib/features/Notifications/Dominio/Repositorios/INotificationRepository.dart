import '../Entidades/NotificationEntiry.dart';

abstract class INotificationRepository {
  Future<void> registerToken(String token, String deviceType);
  Future<void> unregisterToken(String token);
  Future<List<NotificationEntity>> getHistory();
  Future<NotificationEntity> markAsRead(String id);
  Future<void> sendAdminNotification(String message);
}
