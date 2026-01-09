// features/Notifications/Dominio/Entidades/NotificationEntiry.dart

class NotificationEntity {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? resourceId; // Campo opcional mencionado en el DTO

  NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.resourceId,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String, //
      type: json['type'] as String, //
      message: json['message'] as String, //
      isRead: json['isRead'] as bool, //
      // Convertimos el string de la API (ISO 8601) a DateTime
      createdAt: DateTime.parse(json['createdAt'] as String), //
      resourceId: json['resourceId'] as String?, //
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
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? resourceId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      resourceId: resourceId ?? this.resourceId,
    );
  }
}