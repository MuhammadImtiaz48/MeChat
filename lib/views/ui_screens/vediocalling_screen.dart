import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imtiaz/firebase_Services/ringtone_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

const int zegoAppID = 1594596596;
const String zegoAppSign = '305434fc77fd131fb25e505218b60d4caa5e46cea28f1533363190df19e39dd4';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callId;
  final String callType;
  final String userId;
  final String userName;
  final String callerId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callId,
    required this.callType,
    required this.userId,
    required this.userName,
    required this.callerId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;

    final fontSizeTitle = isSmallScreen ? 20.sp : isTablet ? 28.sp : 24.sp;
    final fontSizeSubtitle = isSmallScreen ? 14.sp : isTablet ? 18.sp : 16.sp;
    final buttonSize = isSmallScreen ? 60.w : isTablet ? 80.w : 70.w;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF075E54),
              Color(0xFF128C7E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/chat.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Caller avatar
                    Container(
                      width: isTablet ? 120.w : 100.w,
                      height: isTablet ? 120.w : 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 3.w),
                      ),
                      child: Icon(
                        widget.callType == 'video' ? Icons.videocam : Icons.call,
                        color: Colors.white,
                        size: isTablet ? 50.w : 40.w,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    // Call type
                    Text(
                      widget.callType == 'video' ? 'Video Call' : 'Voice Call',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeSubtitle,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Caller name
                    Text(
                      widget.callerName.isNotEmpty ? widget.callerName : 'Unknown Caller',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    // Incoming text
                    Text(
                      'Incoming call...',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeSubtitle - 2,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.15),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reject Button
                        GestureDetector(
                          onTap: () async {
                            await RingtoneService.stopRingtone();
                            Get.back();
                          },
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Icon(
                              Icons.call_end,
                              size: buttonSize * 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 60.w),
                        // Accept Button
                        GestureDetector(
                          onTap: () async {
                            await RingtoneService.stopRingtone();
                            Get.off(() => ZegoUIKitPrebuiltCall(
                                  appID: zegoAppID,
                                  appSign: zegoAppSign,
                                  userID: widget.userId,
                                  userName: widget.userName.isNotEmpty ? widget.userName : 'User',
                                  callID: widget.callId,
                                  config: widget.callType == 'video'
                                      ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                                      : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
                                ));
                          },
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: Icon(
                              Icons.call,
                              size: buttonSize * 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Button labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle - 4,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 80.w),
                        Text(
                          'Accept',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle - 4,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}