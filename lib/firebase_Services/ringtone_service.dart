// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:http/http.dart' as http;
// import 'package:audioplayers/audioplayers.dart';

// class RingtoneService {
//   static final AudioPlayer _player = AudioPlayer();

//   static Future<void> playRingtone() async {
//     try {
//       await _player.setReleaseMode(ReleaseMode.loop);
//       await _player.play(AssetSource("sounds/ringtone.mp3"));
//       print("✅ Playing ringtone");
//     } catch (e) {
//       print("⚠️ Error playing ringtone: $e");
//     }
//   }

//   static Future<void> stopRingtone() async {
//     try {
//       await _player.stop();
//       print("✅ Stopped ringtone");
//     } catch (e) {
//       print("⚠️ Error stopping ringtone: $e");
//     }
//   }
// }

// class NotificationService {
//   static const _scopes = [
//     "https://www.googleapis.com/auth/firebase.messaging"
//   ];

//   static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static const String _channelId = 'chat_channel_v1';
//   static const String _channelName = 'Chat Notifications';
//   static String? _currentChatId; // Track active chat to suppress notifications

//   /// Set the current chat ID to suppress notifications for the active chat
//   static void setCurrentChatId(String? chatId) {
//     _currentChatId = chatId;
//     print("🔔 Current chat ID set to: $_currentChatId");
//   }

//   /// Initialize local notifications
//   static Future<void> init({
//     required Function(Map<String, dynamic>) onNotificationTap,
//   }) async {
//     try {
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
//       const InitializationSettings initSettings =
//           InitializationSettings(android: androidSettings, iOS: iosSettings);

//       await _localNotificationsPlugin.initialize(
//         initSettings,
//         onDidReceiveNotificationResponse: (details) {
//           if (details.payload != null) {
//             final payloadData = jsonDecode(details.payload!);
//             print("🔔 Notification tapped: $payloadData");
//             onNotificationTap(payloadData);
//           }
//         },
//       );

//       // Create Android notification channel
//       const AndroidNotificationChannel channel = AndroidNotificationChannel(
//         _channelId,
//         _channelName,
//         description: 'Messages and call notifications',
//         importance: Importance.max,
//         playSound: true,
//         sound: RawResourceAndroidNotificationSound('default'),
//       );

//       await _localNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>()
//           ?.createNotificationChannel(channel);
//       print("✅ NotificationService initialized");
//     } catch (e) {
//       print("⚠️ Error initializing NotificationService: $e");
//     }
//   }

//   /// Show local notification with unique ID
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//     String? payload,
//     String? type, // "message" or "call"
//     String? chatId,
//   }) async {
//     try {
//       // Skip if notification is for the active chat
//       if (chatId != null && chatId == _currentChatId) {
//         print("🔔 Suppressed notification for active chat: $chatId");
//         return;
//       }

//       final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         _channelId,
//         _channelName,
//         channelDescription: 'Chat messages & call notifications',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//         sound: type == 'call'
//             ? const RawResourceAndroidNotificationSound('ringtone')
//             : const RawResourceAndroidNotificationSound('default'),
//         groupKey: id.toString(), // Group notifications by chat/call ID
//       );

//       final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentSound: true,
//         sound: type == 'call' ? 'ringtone.caf' : 'default',
//       );

//       final NotificationDetails platformDetails =
//           NotificationDetails(android: androidDetails, iOS: iosDetails);

//       await _localNotificationsPlugin.show(
//         id,
//         title,
//         body,
//         platformDetails,
//         payload: payload,
//       );
//       print("🔔 Notification shown: id=$id, title=$title, body=$body");
//     } catch (e) {
//       print("⚠️ Error showing notification: $e");
//     }
//   }

//   /// Cancel notifications for a specific chat or call
//   static Future<void> cancelNotificationsForChat(String id) async {
//     try {
//       await _localNotificationsPlugin.cancel(id.hashCode);
//       print("✅ Notifications cancelled for ID: $id");
//     } catch (e) {
//       print("⚠️ Error cancelling notifications: $e");
//     }
//   }

//   /// Load FCM service account from assets
//   static Future<Map<String, dynamic>> _loadServiceAccount() async {
//     try {
//       final data = await rootBundle.loadString("assets/notification_json.json");
//       return jsonDecode(data);
//     } catch (e) {
//       print("⚠️ Error loading service account: $e");
//       rethrow;
//     }
//   }

//   /// Get authenticated HTTP client
//   static Future<AutoRefreshingAuthClient> _getAuthClient() async {
//     try {
//       final serviceAccount = await _loadServiceAccount();
//       final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
//       return await clientViaServiceAccount(accountCredentials, _scopes);
//     } catch (e) {
//       print("⚠️ Error getting auth client: $e");
//       rethrow;
//     }
//   }

//   /// Send push notification using FCM HTTP v1
//   /// WARNING: Client-side service account is insecure for production; use server-side (e.g., Cloud Functions)
//   static Future<void> sendPushNotification({
//     required String targetToken,
//     required String title,
//     required String body,
//     required String type, // "message" or "call"
//     required String senderId,
//     required String chatId,
//     required String callId,
//     String? callType,
//     Map<String, String>? data,
//     required String senderName,
//     String? senderEmail,
//     String? senderImage,
//   }) async {
//     try {
//       final client = await _getAuthClient();
//       final serviceAccount = await _loadServiceAccount();
//       final projectId = serviceAccount["project_id"];

//       final url = Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send");

//       final Map<String, String> payloadData = {
//         "type": type,
//         "senderId": senderId,
//         "senderName": senderName,
//         "chatId": chatId,
//         "callId": callId,
//         "callType": callType ?? "",
//         if (senderEmail != null) "senderEmail": senderEmail,
//         if (senderImage != null) "senderImage": senderImage,
//       };

//       if (data != null) payloadData.addAll(data);

//       final message = {
//         "message": {
//           "token": targetToken,
//           "notification": {"title": title, "body": body},
//           "data": payloadData,
//           "android": {
//             "notification": {
//               "sound": type == 'call' ? 'ringtone' : 'default',
//               "channel_id": _channelId,
//             },
//           },
//           "apns": {
//             "payload": {
//               "aps": {
//                 "sound": type == 'call' ? 'ringtone.caf' : 'default',
//               },
//             },
//           },
//         },
//       };

//       final response = await client.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(message),
//       );

//       if (response.statusCode == 200) {
//         print("✅ Notification sent: ${response.body}");
//       } else {
//         print("❌ Notification failed: ${response.statusCode} => ${response.body}");
//       }
//     } catch (e) {
//       print("⚠️ Error sending notification: $e");
//     }
//   }
// }