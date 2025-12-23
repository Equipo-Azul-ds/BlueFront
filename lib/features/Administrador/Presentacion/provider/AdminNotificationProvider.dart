import 'package:Trivvy/features/Notifications/Dominio/Entidades/NotificationEntiry.dart';
import 'package:flutter/material.dart';


class AdminNotificationProvider extends ChangeNotifier {
  // Historial con la estructura de la entidad
  final List<NotificationEntity> _history = [
    NotificationEntity(
      id: '1',
      type: 'admin_notification',
      message: 'Mantenimiento preventivo el viernes',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  bool _isSending = false;

  List<NotificationEntity> get history => _history;
  bool get isSending => _isSending;

  /// Simula el envío a FCM respetando los parámetros de la entidad
  Future<bool> sendAdminNotification(String messageText) async {
    try {
      _isSending = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      final newNotification = NotificationEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'admin_notification',
        message: messageText,
        isRead: false,
        createdAt: DateTime.now(),
      );

      _history.insert(0, newNotification);

      _isSending = false;
      notifyListeners();

      return true; // <--- AÑADIR ESTO
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return false; // <--- Opcional: devolver false si algo falla
    }
  }
}