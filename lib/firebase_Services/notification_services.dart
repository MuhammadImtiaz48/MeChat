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
import 'call_services.dart';

class NotificationService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'chat_channel_v1';
  static const String _channelName = 'Chat Notifications';
  static const String _methodChannel =
      'com.example.flutter_application_1/notifications';
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

      // Use your launcher icon resource name here
      const AndroidInitializationSettings androidSettings =
AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (details) async {
              if (details.payload != null) {
                try {
                  final payloadData =
                      jsonDecode(details.payload!) as Map<String, dynamic>;
                  debugPrint('🔔 NotificationService: Notification tapped: $payloadData');
                  await onNotificationTap(
                      payloadData.map((k, v) => MapEntry(k.toString(), v.toString())));
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

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('🔔 NotificationService: Received foreground message: ${message.notification?.title}');
        }
        try {
          final data = message.data;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (data['senderId'] != currentUserId && data['receiverId'] == currentUserId) {
            final type = data['type'] ?? 'message';
            if (type == 'call') {
              // Handle incoming call directly
              CallService.handleIncomingCall(data);
            } else {
              // Show notification for messages and payments not in current chat
              final shouldShowNotification = type == 'payment' || data['chatId'] != _currentChatId;
              if (shouldShowNotification) {
                showLocalNotification(
                  id: message.messageId?.hashCode ??
                      DateTime.now().millisecondsSinceEpoch,
                  title: message.notification?.title ?? (type == 'payment' ? 'Payment Received' : 'New Message'),
                  body: message.notification?.body ?? (type == 'payment' ? 'You received a payment' : 'You have a new message!'),
                  payload: jsonEncode(data),
                  type: type,
                  chatId: data['chatId'],
                );
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ NotificationService: Error handling onMessage: $e');
        }
      });

      // When app opened from background by tapping notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('🔔 NotificationService: Opened from background message: ${message.notification?.title}');
        }
        try {
          final data = message.data;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (data['senderId'] != currentUserId && data['receiverId'] == currentUserId) {
            onNotificationTap(data.map((k, v) => MapEntry(k.toString(), v.toString())));
            if (data['type'] == 'call') {
              RingtoneService.stopRingtone();
            }
          }
        } catch (e) {
          debugPrint('⚠️ NotificationService: Error handling onMessageOpenedApp: $e');
        }
      });

      // When app opened from terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        final data = initialMessage.data;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (data['senderId'] != currentUserId && data['receiverId'] == currentUserId) {
          if (kDebugMode) {
            debugPrint('🔔 NotificationService: Opened from terminated message: ${initialMessage.notification?.title}');
          }
          try {
            onNotificationTap(data.map((k, v) => MapEntry(k.toString(), v.toString())));
            if (data['type'] == 'call') {
              RingtoneService.stopRingtone();
            }
          } catch (e) {
            debugPrint('⚠️ NotificationService: Error handling initialMessage: $e');
          }
        }
      }

      const MethodChannel methodChannel = MethodChannel(_methodChannel);
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onMessageReceived') {
          final data = call.arguments as Map;
          if (kDebugMode) {
            debugPrint('🔔 NotificationService: Received native message: $data');
          }
          if (data['chatId'] != _currentChatId &&
              data['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
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
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
          }
        }
      });

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔔 NotificationService: FCM token refreshed: $newToken');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': newToken});
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
        playSound: true,
        sound: type == 'call'
            ? const RawResourceAndroidNotificationSound('ringtone')
            : type == 'payment'
                ? const RawResourceAndroidNotificationSound('default')
                : const RawResourceAndroidNotificationSound('default'),
        groupKey: id.toString(),
        fullScreenIntent: type == 'call',
        enableVibration: true,
        category: type == 'call'
            ? AndroidNotificationCategory.call
            : type == 'payment'
                ? AndroidNotificationCategory.message
                : AndroidNotificationCategory.message,
        color: type == 'payment' ? const Color(0xFF4CAF50) : const Color(0xFF25D366), // Green for payments
        ledColor: type == 'payment' ? const Color(0xFF4CAF50) : const Color(0xFF25D366),
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          body ?? '',
          summaryText: title,
          htmlFormatSummaryText: true,
        ),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        icon: '@mipmap/launcher_icon',
        ticker: title,
        when: DateTime.now().millisecondsSinceEpoch,
        showWhen: true,
        autoCancel: true,
        ongoing: type == 'call',
        onlyAlertOnce: false,
        timeoutAfter: type == 'call' ? 30000 : null, // 30 seconds for calls
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
      return jsonDecode(data) as Map<String, dynamic>;
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
    required Map<String, dynamic> payload,
    required String type,
    required String senderId,
    required String chatId,
    required String senderName,
    required String callType,
    required String callId,
    required Map data,
  }) async {
    for (int i = 0; i < 3; i++) {
      try {
        debugPrint('🔔 NotificationService: Sending push notification to $targetToken (attempt ${i + 1})');

        final client = await _getAuthClient();
        final serviceAccount = await _loadServiceAccount();
        final projectId = serviceAccount["project_id"];
        debugPrint('🔔 NotificationService: Using project ID: $projectId');

        final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

        // convert all data values to string (FCM data requires string values)
        final messageData = payload.map((key, value) => MapEntry(key.toString(), value.toString()));

        final androidConfig = {
          'notification': {
            'title': title,
            'body': body,
            'channel_id': _channelId,
            'sound': payload['type'] == 'call' ? 'ringtone' : 'default',
            'color': type == 'payment' ? '#FF4CAF50' : '#FF25D366', // Green for payments
            'icon': '@mipmap/launcher_icon',
            'tag': type == 'payment' ? 'payment_${payload['transactionId']}' : null,
          },
          'priority': type == 'call' || type == 'payment' ? 'high' : 'normal',
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

          try {
            final responseBody = jsonDecode(response.body);
            final errorCode = responseBody['error']?['details']?[0]?['errorCode']?.toString();
            if (errorCode == 'UNREGISTERED' && i < 2) {
              debugPrint('⚠️ NotificationService: Token unregistered, attempting to refresh...');
              await _refreshFcmTokenForUser(senderId);
              final newToken = await _getRefreshedFcmToken(senderId);
              if (newToken != null && newToken != targetToken) {
                debugPrint('✅ NotificationService: Got new token, retrying with new token...');
                return await sendPushNotification(
                  targetToken: newToken,
                  title: title,
                  body: body,
                  payload: payload,
                  type: type,
                  senderId: senderId,
                  chatId: chatId,
                  senderName: senderName,
                  callType: callType,
                  callId: callId,
                  data: data,
                );
              }
            }
          } catch (_) {
            // ignore parse errors
          }

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

  static Future<void> _refreshFcmTokenForUser(String userId) async {
    try {
      debugPrint('🔔 NotificationService: Refreshing FCM token for user: $userId');
      final messaging = FirebaseMessaging.instance;
      final newToken = await messaging.getToken();
      if (newToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': newToken});
        debugPrint('✅ NotificationService: Updated FCM token for user: $userId');
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error refreshing FCM token: $e');
    }
  }

  static Future<String?> _getRefreshedFcmToken(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['fcmToken']?.toString();
    } catch (e) {
      debugPrint('⚠️ NotificationService: Error getting refreshed token: $e');
      return null;
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
