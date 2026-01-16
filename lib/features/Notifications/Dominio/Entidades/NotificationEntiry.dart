// features/Notifications/Dominio/Entidades/NotificationEntiry.dart

class NotificationEntity {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? resourceId;

  NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.resourceId,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resourceId: json['resourceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'resourceId': resourceId,
    };
  }

  NotificationEntity copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? resourceId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      resourceId: resourceId ?? this.resourceId,
    );
  }


}