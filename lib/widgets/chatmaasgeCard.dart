import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ChatMessageCard extends StatelessWidget {
  final String currentUserId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime time;
  final bool seen;
  final bool showSeen;
  final double maxWidth;

  const ChatMessageCard({
    super.key,
    required this.currentUserId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.time,
    required this.seen,
    required this.showSeen,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = senderId == currentUserId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;

    // Responsive dimensions
    final marginHorizontal = isSmallScreen ? 6.w : isTablet ? 12.w : 8.w;
    final paddingHorizontal = isSmallScreen ? 8.w : isTablet ? 16.w : 12.w;
    final paddingVertical = isSmallScreen ? 6.h : isTablet ? 12.h : 8.h;
    final fontSizeMessage = isSmallScreen ? 14.sp : isTablet ? 18.sp : 16.sp;
    final fontSizeTime = isSmallScreen ? 10.sp : isTablet ? 13.sp : 12.sp;
    final iconSize = isSmallScreen ? 14.w : isTablet ? 18.w : 16.w;
    final borderRadius = isSmallScreen ? 10.r : isTablet ? 14.r : 12.r;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? marginHorizontal * 8 : marginHorizontal,
            right: isMe ? marginHorizontal : marginHorizontal * 8,
            top: marginHorizontal * 0.5,
            bottom: marginHorizontal * 0.5,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFD9FDD3) : Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: isTablet ? 6.r : 4.r,
                offset: Offset(0, isTablet ? 3 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: fontSizeMessage,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
              ),
              SizedBox(height: isTablet ? 6.h : 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(time),
                    style: TextStyle(
                      fontSize: fontSizeTime,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (isMe && showSeen) ...[
                    SizedBox(width: isTablet ? 6.w : 4.w),
                    Icon(
                      seen ? Icons.done_all : Icons.done,
                      size: iconSize,
                      color: seen ? Colors.blue : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}