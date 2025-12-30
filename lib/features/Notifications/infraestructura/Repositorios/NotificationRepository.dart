import '../../Application/DataSource/INotificationDatasource.dart';
import '../../Dominio/Entidades/NotificationEntiry.dart';
import '../../Dominio/Repositorios/INotificationRepository.dart';


class NotificationRepository implements INotificationRepository {
  final INotificationDataSource dataSource;

  NotificationRepository({required this.dataSource});

  @override
  Future<List<NotificationEntity>> getHistory() async {
    // Llama al GET /notifications
    final List<dynamic> rawData = await dataSource.getNotificationHistory();

    // Mapea la lista de DTOs a Entidades
    return rawData.map((json) => NotificationEntity.fromJson(json)).toList();
  }

  @override
  Future<NotificationEntity> markAsRead(String id) async {
    // Llama al PATCH /notifications/:id
    final Map<String, dynamic> updatedData = await dataSource.markAsRead(id);

    // Retorna el objeto actualizado
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