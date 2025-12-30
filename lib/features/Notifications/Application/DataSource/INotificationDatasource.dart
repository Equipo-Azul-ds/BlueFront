abstract class INotificationDataSource {
  Future<void> registerDevice(String token, String deviceType);
  Future<void> unregisterDevice(String token);
  Future<List<dynamic>> getNotificationHistory();
  Future<Map<String, dynamic>> markAsRead(String id);
  Future<void> sendAdminNotification(String message);
}