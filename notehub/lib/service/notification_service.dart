import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(settings: initSettings);
  }

  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'notes_channel',
      'Notes Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platform = NotificationDetails(android: android);
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platform,
      payload: payload,
    );
  }
}
