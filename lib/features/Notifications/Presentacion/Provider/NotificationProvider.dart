import 'package:Trivvy/features/Notifications/Dominio/Entidades/NotificationEntiry.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../Dominio/Repositorios/INotificationRepository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';




class NotificationProvider extends ChangeNotifier {

  final INotificationRepository repository;

  NotificationProvider({required this.repository});
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

  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> initNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Solicitar permisos
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          // Registrar token en el backend
          await registerDeviceToken(fcmToken);
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Notificación recibida en primer plano: ${message.notification?.title}');

          _handleIncomingMessage(message);

          _showForegroundNotification(message);
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _handleIncomingMessage(RemoteMessage message) {
    final newNotif = NotificationEntity(
      id: message.messageId ?? DateTime.now().toString(),
      type: message.data['type'] ?? 'admin_notification', // [cite: 1]
      message: message.notification?.body ?? 'Nuevo mensaje recibido',
      isRead: false,
      createdAt: DateTime.now(),
    );

    _history.insert(0, newNotif);
    notifyListeners();
  }

  void _showForegroundNotification(RemoteMessage message) {
    final snackBar = SnackBar(
      backgroundColor: AppColor.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.notification?.title ?? 'Notificación',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            message.notification?.body ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,

    );

    messengerKey.currentState?.showSnackBar(snackBar);
  }

  /// Registra el token FCM en el servidor usando el DTO RegisterDeviceDto
  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      // Se envía el token y el deviceType 'android' como indica el esqueleto JSON
      await repository.registerToken(fcmToken, "android");
      print("Token registrado exitosamente en el backend.");
    } catch (e) {
      print("Fallo el registro del token en el servidor: $e");
    }
  }



  /// Elimina el token
  Future<void> logoutDevice(String fcmToken) async {
    try {
      await repository.unregisterToken(fcmToken); // [cite: 4]
      print("Dispositivo desvinculado");
    } catch (e) {
      print("Error en unregister: $e");
    }
  }

  Future<void> fetchHistory() async {
    try {
      final List<dynamic> data = await repository.getHistory();
      _history.clear();
      _history.addAll(data.map((json) => NotificationEntity.fromJson(json)).toList());
      notifyListeners();
    } catch (e) {
      print("Error al cargar historial: $e");
    }
  }

  /// Acción implícita: Marcar como leída
  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id); //
      final index = _history.indexWhere((n) => n.id == id);
      if (index != -1) {
        // Actualizamos localmente para feedback inmediato
        _history[index] = _history[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print("Error al marcar como leída: $e");
    }
  }

  /// Implementación PROPIA de envío de administrador (No simulación)
  Future<bool> sendAdminNotification(String messageText) async {
    try {
      _isSending = true;
      notifyListeners();

      // Llamada real al backend
      await repository.sendAdminNotification(messageText);

      // Opcional: Recargar historial tras enviar
      await fetchHistory();

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  void simulateIncomingNotification() {
    // 1. Creamos un objeto que simule la estructura de RemoteMessage de Firebase
    // Basado en el tipo de notificación del backend
    final String mockTitle = "Aviso del Sistema";
    final String mockBody = "¡Prueba de notificación exitosa con tus colores!";

    // 2. Mostramos el SnackBar usando tus colores de AppColor
    final snackBar = SnackBar(
      backgroundColor: AppColor.primary, // Deep blue
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mockTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.onPrimary),
          ),
          Text(
            mockBody,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: SnackBarAction(
        label: 'CERRAR',
        textColor: AppColor.accent, // Azul vibrante
        onPressed: () {},
      ),
    );

    messengerKey.currentState?.showSnackBar(snackBar);

    // 3. Lo agregamos al historial local (Entity)
    final mockEntity = NotificationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'admin_notification', // Tipo definido en el DTO
      message: mockBody,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _history.insert(0, mockEntity);
    notifyListeners();
  }

  Future<void> printCurrentToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("---------------- FCM TOKEN ----------------");
        print(token);
        print("-------------------------------------------");

        // Opcional: Mostrar un SnackBar para confirmar que se obtuvo
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Token impreso en consola')),
        );
      } else {
        print("No se pudo obtener el token.");
      }
    } catch (e) {
      print("Error al obtener el token: $e");
    }
  }
}