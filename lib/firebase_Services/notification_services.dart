// lib/firebase_Services/notification_services.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:imtiaz/main.dart'; // for flutterLocalNotificationsPlugin

class NotificationService {
  static const _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  static Future<Map<String, dynamic>> _loadServiceAccount() async {
    final raw = await rootBundle.loadString('assets/notification_json.json');
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final sa = await _loadServiceAccount();
    final creds = ServiceAccountCredentials.fromJson(sa);
    return clientViaServiceAccount(creds, _scopes);
  }

  static Future<String?> _sendFCM(Map<String, dynamic> messageBody) async {
    try {
      final sa = await _loadServiceAccount();
      final client = await _getAuthClient();

      final projectId = sa['project_id'];
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final resp = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(messageBody),
      );
      client.close();

      if (resp.statusCode == 200) {
        return resp.body; // success
      } else {
        print('FCM error ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      print('FCM exception: $e');
      return null;
    }
  }

  /// Send a **chat message** notification
  static Future<bool> sendMessagePush({
    required String toToken,
    required String senderName,
    required String previewText,
    String? chatId,
  }) async {
    final body = {
      "message": {
        "token": toToken,
        "notification": {
          "title": senderName,
          "body": previewText,
        },
        "data": {
          "type": "message",
          if (chatId != null) "chatId": chatId,
          "senderName": senderName,
          "preview": previewText,
        },
        "android": {
          "priority": "HIGH",
          "notification": {"sound": "default"}
        },
        "apns": {
          "payload": {
            "aps": {"sound": "default", "content-available": 1}
          }
        }
      }
    };

    final res = await _sendFCM(body);
    return res != null;
  }

  /// Send a **call invitation** notification (voice/video)
  static Future<bool> sendCallInvite({
    required String toToken,
    required String callerName,
    required String callId,
    required String callType, // "voice" | "video"
  }) async {
    final body = {
      "message": {
        "token": toToken,
        "notification": {
          "title": "Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call",
          "body": "$callerName is calling you",
        },
        "data": {
          "type": "call",
          "callType": callType,
          "callId": callId,
          "callerName": callerName,
        },
        "android": {
          "priority": "HIGH",
          "notification": {"sound": "default"}
        },
        "apns": {
          "payload": {
            "aps": {"sound": "default"}
          }
        }
      }
    };

    final res = await _sendFCM(body);
    return res != null;
  }

  /// ✅ Show a **local call notification** with ringtone & full screen intent
  static Future<void> showCallNotification({
    required String callerName,
    required String callId,
    required String callType, // voice | video
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mechat_channel_id',
      'MeChat Notifications',
      channelDescription: 'Incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true, // makes it like an incoming call screen
      ticker: 'Incoming call',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
      '$callerName is calling you',
      notificationDetails,
      payload: callId,
    );
  }
}
