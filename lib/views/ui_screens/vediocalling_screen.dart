import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imtiaz/firebase_Services/ringtone_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String callId;
  final String callType;
  final String userId;
  final String userName;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callId,
    required this.callType,
    required this.userId,
    required this.userName, required callerId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;

    final fontSizeTitle = isSmallScreen ? 20.sp : isTablet ? 28.sp : 24.sp;
    final fontSizeSubtitle = isSmallScreen ? 14.sp : isTablet ? 18.sp : 16.sp;
    final buttonSize = isSmallScreen ? 60.w : isTablet ? 80.w : 70.w;

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'From: $callerName',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeSubtitle,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 50.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Accept Button
                  GestureDetector(
                    onTap: () async {
                      await RingtoneService.stopRingtone();
                      Get.off(() => ZegoUIKitPrebuiltCall(
                            appID: 116174848,
                            appSign:
                                '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679',
                            userID: userId,
                            userName: userName.isNotEmpty ? userName : 'User',
                            callID: callId,
                            config: callType == 'video'
                                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
                          ));
                    },
                    child: CircleAvatar(
                      radius: buttonSize / 2,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.call, size: buttonSize * 0.5, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 40.w),
                  // Reject Button
                  GestureDetector(
                    onTap: () async {
                      await RingtoneService.stopRingtone();
                      Get.back();
                    },
                    child: CircleAvatar(
                      radius: buttonSize / 2,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.call_end, size: buttonSize * 0.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}