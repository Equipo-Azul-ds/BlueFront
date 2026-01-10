import '../../Dominio/DataSource/INotificationDatasource.dart';
import '../../Dominio/Entidades/AdminNotificacation.dart';
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

  @override
  Future<void> sendMassNotification({
    required String title,
    required String message,
    required bool toAdmins,
    required bool toRegularUsers,
  }) async {
    // Llama al endpoint POST /backoffice/massNotification
    await dataSource.sendMassNotification(
      title: title,
      message: message,
      toAdmins: toAdmins,
      toRegularUsers: toRegularUsers,
    );
  }

  @override
  Future<List<AdminNotificationEntity>> getAdminNotificationHistory({
    int limit = 20,
    int page = 1,
    String? userId,
  }) async {

    final responseDto = await dataSource.getAdminNotificationHistory(
      limit: limit,
      page: page,
      userId: userId,
    );

    return responseDto.notifications; // Devuelve List<AdminNotificationEntity>
  }


}