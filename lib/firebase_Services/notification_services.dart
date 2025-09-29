import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RingtoneService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playRingtone() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/ringtone.mp3'));
      debugPrint('✅ RingtoneService: Playing ringtone');
    } catch (e) {
      debugPrint('⚠️ RingtoneService: Error playing ringtone: $e');
    }
  }

  static Future<void> stopRingtone() async {
    try {
      await _player.stop();
      debugPrint('✅ RingtoneService: Stopped ringtone');
    } catch (e) {
      debugPrint('⚠️ RingtoneService: Error stopping ringtone: $e');
    }
  }
}

class NotificationService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'chat_channel_v1';
  static const String _channelName = 'Chat Notifications';
  static String? _currentChatId;

  static void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
    debugPrint('🔔 NotificationService: Current chat ID set to: $_currentChatId');
  }

  static Future<void> init({
    required Function(Map<String, String>) onNotificationTap,
  }) async {
    try {
      debugPrint('🔔 NotificationService: Initializing');
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotificationsPlugin
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (details) async {
              if (details.payload != null) {
                try {
                  final payloadData = jsonDecode(details.payload!) as Map<String, dynamic>;
                  debugPrint('🔔 NotificationService: Notification tapped: $payloadData');
                  await onNotificationTap(payloadData.cast<String, String>());
                } catch (e) {
                  debugPrint('⚠️ NotificationService: Error parsing notification payload: $e');
                }
              }
            },
          )
          .timeout(const Duration(seconds: 3), onTimeout: () {
            debugPrint('⚠️ NotificationService: Initialization timed out');
            return false;
          });

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Messages and call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('default'),
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('✅ NotificationService: Initialized');
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error initializing: $e');
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? type,
    String? chatId,
  }) async {
    try {
      if (chatId != null && chatId == _currentChatId) {
        debugPrint('🔔 NotificationService: Suppressed local notification for active chat: $chatId');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Chat messages & call notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: type == 'call' ? const RawResourceAndroidNotificationSound('ringtone') : const RawResourceAndroidNotificationSound('default'),
        groupKey: id.toString(),
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        sound: type == 'call' ? 'ringtone.caf' : 'default',
      );

      final NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotificationsPlugin.show(id, title, body, platformDetails, payload: payload);
      debugPrint('🔔 NotificationService: Local notification shown: id=$id, title=$title, body=$body');
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error showing local notification: $e');
    }
  }

  static Future<void> cancelNotificationsForChat(String id) async {
    try {
      await _localNotificationsPlugin.cancel(id.hashCode);
      debugPrint('✅ NotificationService: Notifications cancelled for ID: $id');
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error cancelling notifications: $e');
    }
  }

  static Future<Map<String, dynamic>> _loadServiceAccount() async {
    try {
      final data = await rootBundle.loadString('assets/notification_json.json').timeout(const Duration(seconds: 2));
      return jsonDecode(data);
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error loading service account: $e');
      rethrow;
    }
  }

  static Future<AutoRefreshingAuthClient> _getAuthClient() async {
    try {
      final serviceAccount = await _loadServiceAccount();
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
      return await clientViaServiceAccount(accountCredentials, _scopes).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error getting auth client: $e');
      rethrow;
    }
  }

  static Future<bool> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    required Map<String, String> payload, required String type, required String senderId, required String chatId, required String senderName, required String callType, required String callId, required Map data,
  }) async {
    try {
      debugPrint('🔔 NotificationService: Sending push notification to $targetToken');
      final client = await _getAuthClient();
      final serviceAccount = await _loadServiceAccount();
      final projectId = serviceAccount['project_id'];

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      // Build notification data based on payload type
      final notificationData = {
        'title': title,
        'body': body,
        'sound': payload['type'] == 'call' ? 'ringtone' : 'default',
      };

      final androidConfig = {
        'notification': {
          ...notificationData,
          'channel_id': _channelId,
        },
      };

      final apnsConfig = {
        'payload': {
          'aps': {
            ...notificationData,
            'sound': payload['type'] == 'call' ? 'ringtone.caf' : 'default',
          },
        },
      };

      final message = {
        'message': {
          'token': targetToken,
          'notification': notificationData,
          'data': payload,
          'android': androidConfig,
          'apns': apnsConfig,
        },
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ NotificationService: Notification sent: ${response.body}');
        return true;
      } else {
        debugPrint('❌ NotificationService: Notification failed: ${response.statusCode} => ${response.body}');
        _showErrorSnackbar('Failed to send notification');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error sending notification: $e');
      _showErrorSnackbar('Failed to send notification: Network error');
      return false;
    }
  }

  static void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 10.r,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 3),
      titleText: Text(
        'Error',
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}