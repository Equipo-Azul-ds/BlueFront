import 'package:Trivvy/features/Notifications/Dominio/Entidades/NotificationEntiry.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../Dominio/Entidades/AdminNotificacation.dart';
import '../../Dominio/Repositorios/INotificationRepository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';




class NotificationProvider extends ChangeNotifier {

  final INotificationRepository repository;

  NotificationProvider({required this.repository});
  List<NotificationEntity> _history = [];
  List<AdminNotificationEntity> _adminHistory = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;

  List<NotificationEntity> get history => _history;
  List<AdminNotificationEntity> get adminHistory => _adminHistory;
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
      type: message.data['type'] ?? 'admin_notification',
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


  Future<void> registerDeviceToken(String fcmToken) async {
    try {

      await repository.registerToken(fcmToken, "android");
      print("Token registrado exitosamente en el backend.");
    } catch (e) {
      print("Fallo el registro del token en el servidor: $e");
    }
  }


  Future<void> logoutDevice(String fcmToken) async {
    try {
      await repository.unregisterToken(fcmToken); // [cite: 4]
      print("Dispositivo desvinculado");
    } catch (e) {
      print("Error en unregister: $e");
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await repository.getHistory();
      _history = data;
      print("Historial cargado: ${_history.length} elementos");
    } catch (e) {
      print("Error real al cargar historial: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id); //
      final index = _history.indexWhere((n) => n.id == id);
      if (index != -1) {
        // Actualiza localmente para feedback inmediato
        _history[index] = _history[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print("Error al marcar como leída: $e");
    }
  }

  Future<void> enableNotifications() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await registerDeviceToken(token); // Llama al POST /notifications/register-device
      notifyListeners();
    }
  }

  Future<void> disableNotifications() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await logoutDevice(token); // Llama al DELETE /notifications/unregister-device
      notifyListeners();
    }
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
          SnackBar(content: Text('Token = $token')),
        );
      } else {
        print("No se pudo obtener el token.");
      }
    } catch (e) {
      print("Error al obtener el token: $e");
    }
  }

  Future<void> sendMassiveNotification({
    required String title,
    required String message,
    required bool toAdmins,
    required bool toRegularUsers,
  }) async {
    _isSending = true;
    notifyListeners();

    try {
      await repository.sendMassNotification(
        title: title,
        message: message,
        toAdmins: toAdmins,
        toRegularUsers: toRegularUsers,
      );

      _showSnackBar('Notificación enviada con éxito', isError: false);
      await loadAdminHistory();
    } catch (e) {
      _showSnackBar('Error al enviar: $e', isError: true);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminHistory({int page = 1}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newNotifications = await repository.getAdminNotificationHistory(
        page: page,
        limit: 20,
      );

      if (page == 1) {
        _adminHistory = newNotifications;
      } else {
        _adminHistory.addAll(newNotifications);
      }
    } catch (e) {
      print('Error en Provider: $e');
      _showSnackBar('Error al cargar historial administrativo', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await repository.getHistory();
    } catch (e) {
      _showSnackBar('Error al cargar tus notificaciones', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper para notificaciones visuales
  void _showSnackBar(String message, {bool isError = false}) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}