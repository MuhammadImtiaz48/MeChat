import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:google_fonts/google_fonts.dart';

class UserChatCard extends StatelessWidget {
  final UserchatModel user;
  final VoidCallback onTap;
  final String loggedInUserName;

  const UserChatCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.loggedInUserName, required String currentUserId, required String senderId, required String senderName, required String message, required time, required seen, required showSeen, required maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final fontSizeTitle = isSmallScreen ? 16.sp : isTablet ? 20.sp : 18.sp;
    final fontSizeSubtitle = isSmallScreen ? 12.sp : isTablet ? 14.sp : 13.sp;
    final avatarRadius = isSmallScreen ? 24.r : isTablet ? 32.r : 28.r;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
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
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF075E54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.email.isNotEmpty ? user.email : 'No email',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF075E54),
              size: isTablet ? 18.w : 16.w,
            ),
          ],
        ),
      ),
    );
  }
}