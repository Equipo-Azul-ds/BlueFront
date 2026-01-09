import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;

  static Future initialize() async {
    // 1. Solicitar permisos (Vital para iOS y Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Obtener el Token del dispositivo
    token = await messaging.getToken();
    print("FCM Token: $token"); // Este token es el que guardas en tu DB

    // 3. Listeners para diferentes estados

    // APP EN PRIMER PLANO (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje en primer plano: ${message.notification?.title}');
      // Aquí usarías flutter_local_notifications para mostrar un banner
    });

    // APP EN SEGUNDO PLANO PERO ABIERTA (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('El usuario tocó la notificación: ${message.data}');
    });
  }
}