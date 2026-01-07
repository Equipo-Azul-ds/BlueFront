import '../DTO/NotificationListResponseDTO.dart';

abstract class INotificationDataSource {
  Future<void> registerDevice(String token, String deviceType);
  Future<void> unregisterDevice(String token);
  Future<NotificationListResponseDto> getNotificationHistory({int limit, int page});
  Future<Map<String, dynamic>> markAsRead(String id);
  Future<void> sendAdminNotification(String message);
}