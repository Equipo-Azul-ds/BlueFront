// features/Notifications/Application/DTO/AdminNotificationListResponseDTO.dart
import '../../Dominio/Entidades/AdminNotificacation.dart';


class AdminNotificationListResponseDto {
  final List<AdminNotificationEntity> notifications;

  AdminNotificationListResponseDto({required this.notifications});

  factory AdminNotificationListResponseDto.fromDynamicJson(dynamic json) {
    List<dynamic> dataList = [];

    if (json is List) {
      dataList = json;
    } else if (json is Map<String, dynamic>) {
      dataList = (json['data'] ?? json['notifications'] ?? []) as List<dynamic>;
    }

    return AdminNotificationListResponseDto(
      notifications: dataList
          .map((item) => AdminNotificationEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}