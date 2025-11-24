import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserChatCard extends StatelessWidget {
   final UserchatModel user;
   final VoidCallback onTap;
   final VoidCallback? onLongPress;
   final VoidCallback? onAvatarTap;
   final String loggedInUserName;

   const UserChatCard({
     super.key,
     required this.user,
     required this.onTap,
     required this.loggedInUserName,
     this.onLongPress,
     this.onAvatarTap,
     String? currentUserId,
     String? senderId,
     String? senderName,
     String? message,
     dynamic time,
     dynamic seen,
     dynamic showSeen,
     dynamic maxWidth,
   });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  bool _isOnline(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inMinutes < 5; // Consider online if active within last 5 minutes
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final fontSizeTitle = isSmallScreen ? 16.sp : isTablet ? 20.sp : 18.sp;
    final fontSizeSubtitle = isSmallScreen ? 12.sp : isTablet ? 14.sp : 13.sp;
    final avatarRadius = isSmallScreen ? 24.r : isTablet ? 32.r : 28.r;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF121212)
              : const Color(0xFFECE5DD),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[300],
                backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                child: user.profilePic.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: avatarRadius * 1.1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name.isNotEmpty ? user.name : 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF075E54),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          child: Text(
                            user.unreadCount > 99 ? '99+' : user.unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeSubtitle - 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.lastMessage.isNotEmpty ? user.lastMessage : (user.email.isNotEmpty ? user.email : 'No email'),
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? (user.lastMessage.isNotEmpty ? Colors.grey[300] : Colors.grey[400])
                                : (user.lastMessage.isNotEmpty ? Colors.grey[700] : Colors.grey[600]),
                            fontWeight: user.lastMessage.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (user.lastMessageTime != null) ...[
                        SizedBox(width: 8.w),
                        Text(
                          _formatTime(user.lastMessageTime!),
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle - 2,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (user.lastActive != null) ...[
              SizedBox(width: 8.w),
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: _isOnline(user.lastActive!) ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : const Color(0xFF075E54),
              size: isTablet ? 18.w : 16.w,
            ),
          ],
        ),
      ),
    );
  }
}