import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize local notification settings
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(settings);
  }

  /// Show call notification
  static Future<void> showCallNotification({
    required String callerName,
    required int id,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'call_channel', // channel id
      'Incoming Calls', // channel name
      channelDescription: 'This channel is used for incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // 🔔 makes it behave like a call popup
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      'Incoming Call',
      'Call from $callerName',
      platformDetails,
    );
  }

  /// Cancel a notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
