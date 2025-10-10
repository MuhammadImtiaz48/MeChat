import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ringtone_service.dart';

class NotificationService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'chat_channel_v1';
  static const String _channelName = 'Chat Notifications';
  static const String _methodChannel = 'com.example.flutter_application_1/notifications';
  static String? _currentChatId;

  static void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
    if (kDebugMode) {
      debugPrint('🔔 NotificationService: Current chat ID set to: $_currentChatId');
    }
  }

  static Future<void> init({
    required Function(Map<String, String>) onNotificationTap,
  }) async {
    try {
      debugPrint('🔔 NotificationService: Initializing');
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('launcher_icon');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (details) async {
              if (details.payload != null) {
                try {
                  final payloadData = jsonDecode(details.payload!) as Map<String, dynamic>;
                  debugPrint('🔔 NotificationService: Notification tapped: $payloadData');
                  await onNotificationTap(payloadData.cast<String, String>());
                  if (payloadData['type'] == 'call') {
                    await RingtoneService.stopRingtone();
                  }
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

      const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Messages and call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('default'),
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(notificationChannel);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('🔔 NotificationService: Received foreground message: ${message.notification?.title}');
        }
        if (message.data['chatId'] != _currentChatId && message.data['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
          showLocalNotification(
            id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
            title: message.notification?.title ?? 'New Message',
            body: message.notification?.body ?? 'You have a new message!',
            payload: jsonEncode(message.data),
            type: message.data['type'],
            chatId: message.data['chatId'],
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('🔔 NotificationService: Opened from background message: ${message.notification?.title}');
        }
        if (message.data['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
          onNotificationTap(message.data.cast<String, String>());
          if (message.data['type'] == 'call') {
            RingtoneService.stopRingtone();
          }
        }
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
        if (kDebugMode) {
          debugPrint('🔔 NotificationService: Opened from terminated message: ${initialMessage.notification?.title}');
        }
        onNotificationTap(initialMessage.data.cast<String, String>());
        if (initialMessage.data['type'] == 'call') {
          RingtoneService.stopRingtone();
        }
      }

      const MethodChannel methodChannel = MethodChannel(_methodChannel);
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onMessageReceived') {
          final data = call.arguments as Map;
          if (kDebugMode) {
            debugPrint('🔔 NotificationService: Received native message: $data');
          }
          if (data['chatId'] != _currentChatId && data['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
            showLocalNotification(
              id: data['messageId']?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
              title: data['title'] ?? 'New Message',
              body: data['body'] ?? 'You have a new message!',
              payload: jsonEncode(data),
              type: data['type'],
              chatId: data['chatId'],
            );
          }
        } else if (call.method == 'onNewToken') {
          final token = call.arguments as String;
          if (kDebugMode) {
            debugPrint('🔔 NotificationService: New FCM token: $token');
          }
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'fcmToken': token});
          }
        }
      });

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
        playSound: type != 'call',
        sound: type == 'call' ? null : const RawResourceAndroidNotificationSound('default'),
        groupKey: id.toString(),
        fullScreenIntent: type == 'call',
      );

      final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(id, title, body, platformDetails, payload: payload);
      debugPrint('🔔 NotificationService: Local notification shown: id=$id, title=$title, body=$body');

      if (type == 'call') {
        await RingtoneService.playRingtone();
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error showing local notification: $e');
    }
  }

  static Future<void> cancelNotificationsForChat(String id) async {
    try {
      await _localNotificationsPlugin.cancel(id.hashCode);
      await RingtoneService.stopRingtone();
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
    required Map<String, dynamic> payload, required String type, required String senderId, required String chatId, required String senderName, required String callType, required String callId, required Map data,
  }) async {
    for (int i = 0; i < 3; i++) {
      try {
        debugPrint('🔔 NotificationService: Sending push notification to $targetToken (attempt ${i + 1})');
        final client = await _getAuthClient();
        final serviceAccount = await _loadServiceAccount();
        final projectId = serviceAccount["project_id"];
        debugPrint('🔔 NotificationService: Using project ID: $projectId');

        final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

        final messageData = payload.map((key, value) => MapEntry(key, value.toString()));

        final androidConfig = {
          'notification': {
            'title': title,
            'body': body,
            'channel_id': _channelId,
            'sound': payload['type'] == 'call' ? 'ringtone' : 'default',
          },
          'data': messageData,
        };

        final message = {
          'message': {
            'token': targetToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': messageData,
            'android': androidConfig,
          },
        };

        final response = await client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(message),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          debugPrint('✅ NotificationService: Notification sent: ${response.body}');
          return true;
        } else {
          debugPrint('❌ NotificationService: Notification failed: ${response.statusCode} => ${response.body}');
          if (i == 2) {
            _showErrorSnackbar('Failed to send notification: ${response.statusCode}');
            return false;
          }
        }
      } catch (e) {
        debugPrint('⚠️ NotificationService: Error sending notification: $e');
        if (i == 2) {
          _showErrorSnackbar('Failed to send notification: $e');
          return false;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
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