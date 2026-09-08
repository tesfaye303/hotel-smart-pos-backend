import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 1. አፕሊኬሽኑ ከተዘጋ በኋላ (Background) ለሚመጡ ማሳወቂያዎች ይሰራል
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // ፈቃድ መጠየቅ
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background Handler መመዝገብ
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Local Notifications ማስተካከል (በድምፅ እንዲያበስር)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // 2. Foreground (አፑ ክፍት እያለ) ትዕዛዝ ሲደርስ በድምፅ ማሳወቂያ ማሳየት
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'አዲስ ትዕዛዝ!',
          body: notification.body ?? 'አዲስ ትዕዛዝ ደርሷል።',
        );
      }
    });
  }

  // Local Notification ማሳያ Function
  Future<void> _showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pos_orders_channel',
      'Order Notifications',
      channelDescription: 'Kitchen and Waitress Order Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  // ለወጥ ቤት ወይም ለካሸር Topic Subscribe ማድረግ
  Future<void> subscribeToRoleTopic(String role) async {
    // ለምሳሌ 'kitchen', 'waitress', 'cashier'
    await _firebaseMessaging.subscribeToTopic(role);
  }
}