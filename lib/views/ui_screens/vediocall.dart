import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class VedioCallingScreen extends StatelessWidget {
  final String callId;
  final bool isVideoCall;
  final String callerName;
  final String callerId;

  // ⚡ Constructor
  const VedioCallingScreen({
    super.key,
    required this.callId,
    required this.isVideoCall,
    required this.callerName,
    required this.callerId,
  });

  // Zego App Credentials (tumhare project k hisab se set karo)
  static const int zegoAppID = 116174848;
  static const String zegoAppSign =
      "07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: zegoAppID,
          appSign: zegoAppSign,
          userID: callerId,
          userName: callerName,
          callID: callId,
          config: isVideoCall
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        ),
      ),
    );
  }
}
