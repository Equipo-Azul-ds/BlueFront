import '../../Dominio/Entidades/NotificationEntiry.dart';

class NotificationListResponseDto {
  final List<NotificationEntity> notifications;

  NotificationListResponseDto({required this.notifications});


  factory NotificationListResponseDto.fromDynamicJson(dynamic json) {

    if (json is List) {
      return NotificationListResponseDto(
        notifications: json
            .map((item) => NotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      // El backend parece devolver la lista en la llave 'data'
      final List<dynamic> dataList = (json['data'] ?? json['notifications'] ?? []) as List<dynamic>;
      return NotificationListResponseDto(
        notifications: dataList
            .map((item) => NotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    throw Exception("Formato de respuesta de notificaciones no reconocido");
  }
}