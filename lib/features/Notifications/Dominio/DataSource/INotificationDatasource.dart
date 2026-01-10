import '../../Application/DTO/NotificationListResponseDTO.dart';


abstract class INotificationDataSource {
  Future<void> registerDevice(String token, String deviceType);
  Future<void> unregisterDevice(String token);
  Future<NotificationListResponseDto> getNotificationHistory({int limit, int page});
  Future<Map<String, dynamic>> markAsRead(String id);
  Future<void> sendAdminNotification(String message);
  Future<Map<String, dynamic>> sendMassNotification({
    required String title,
    required String message,
    required bool toAdmins,
    required bool toRegularUsers,
  });

  Future<NotificationListResponseDto> getAdminNotificationHistory({
    int limit = 20,
    int page = 1,
    String? userId,
  });
}