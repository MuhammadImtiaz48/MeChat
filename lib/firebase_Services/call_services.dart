import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/firebase_Services/notification_services.dart';
import 'package:imtiaz/firebase_Services/ringtone_service.dart';
import 'package:imtiaz/views/ui_screens/vediocall.dart';
import 'package:imtiaz/views/ui_screens/vediocalling_screen.dart';
import 'package:imtiaz/views/ui_screens/vediocalling_screen.dart';


class CallService {
  static bool _isCallScreenOpen = false;

  /// Handle incoming call (receiver side)
  static void handleIncomingCall(Map<String, dynamic> data) {
    if (_isCallScreenOpen) return;

    final callerName = data['senderName'] ?? "Unknown";
    final callerId = data['senderId'] ?? "";
    final callId = data['callId'] ?? "";
    final callType = data['callType'] ?? "video";

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    final userName = currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';

    _isCallScreenOpen = true;
    RingtoneService.playRingtone();

    if (Get.context != null) {
      Get.dialog(
        IncomingCallScreen(
          callerName: callerName,
          callerId: callerId,
          callId: callId,
          callType: callType,
          userId: userId,
          userName: userName,
        ),
        barrierDismissible: false,
      ).then((_) {
        _isCallScreenOpen = false;
        RingtoneService.stopRingtone();
      });
    }
  }

  /// Start a call (caller side)
  static Future<void> startCall({
    required String targetToken,
    required String chatId,
    required bool isVideo,
    required String callerName,
    required String callerId,
  }) async {
    // 🔔 Send FCM push to receiver
    await NotificationService.sendPushNotification(
      targetToken: targetToken,
      title: "Incoming ${isVideo ? "Video" : "Voice"} Call",
      body: "$callerName is calling you",
      type: "call",
      senderId: callerId,
      senderName: callerName,
      chatId: chatId,
      callId: chatId,
      callType: isVideo ? "video" : "voice",
      data: {}, payload: {},
    );

    // 📞 Caller directly joins call screen
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (_) => VedioCallingScreen(
          callId: chatId,
          isVideoCall: isVideo,
          callerName: callerName,
          callerId: callerId,
        ),
      ),
    );
  }

  /// Reject call
  static void rejectCall() {
    if (_isCallScreenOpen) {
      _isCallScreenOpen = false;
      RingtoneService.stopRingtone();
      Get.back(); // Close IncomingCallScreen
    }
  }

  /// Accept call
  static void acceptCall({
    required String callId,
    required String callerName,
    required String callerId,
    required bool isVideo,
  }) {
    _isCallScreenOpen = false;
    RingtoneService.stopRingtone();

    Navigator.pushReplacement(
      Get.context!,
      MaterialPageRoute(
        builder: (_) => VedioCallingScreen(
          callId: callId,
          isVideoCall: isVideo,
          callerName: callerName,
          callerId: callerId,
        ),
      ),
    );
  }
}
