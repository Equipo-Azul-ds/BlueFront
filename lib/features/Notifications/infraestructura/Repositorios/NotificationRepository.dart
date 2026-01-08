import '../../Application/DataSource/INotificationDatasource.dart';
import '../../Dominio/Entidades/NotificationEntiry.dart';
import '../../Dominio/Repositorios/INotificationRepository.dart';


class NotificationRepository implements INotificationRepository {
  final INotificationDataSource dataSource;

  NotificationRepository({required this.dataSource});

  @override
  Future<List<NotificationEntity>> getHistory() async {
    final responseDto = await dataSource.getNotificationHistory();

    return responseDto.notifications;
  }

  @override
  Future<NotificationEntity> markAsRead(String id) async {
    final Map<String, dynamic> updatedData = await dataSource.markAsRead(id);
    return NotificationEntity.fromJson(updatedData);
  }

  @override
  Future<void> registerToken(String token, String deviceType) {
    return dataSource.registerDevice(token, deviceType);
  }

  @override
  Future<void> unregisterToken(String token) {
    return dataSource.unregisterDevice(token);
  }

  @override
  Future<void> sendAdminNotification(String message) {
    return dataSource.sendAdminNotification(message);
  }
}