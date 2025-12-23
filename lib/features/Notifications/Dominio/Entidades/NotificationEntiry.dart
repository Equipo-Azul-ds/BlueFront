class NotificationEntity {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? resourceId;

  NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.resourceId,
  });
}