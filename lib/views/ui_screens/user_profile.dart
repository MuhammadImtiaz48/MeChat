import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:shimmer/shimmer.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({super.key, required this.userId, required this.userName, required UserchatModel user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7986CB)),
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        title: Text(
          userName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: const Color(0xFF075E54),
              ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFF075E54).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState(context);
                  }
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return _buildErrorState(context, 'User data not found', controller);
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final profilePic = data?['profilePic']?.toString() ?? '';
                  final email = data?['email']?.toString() ?? 'No email';
                  final lastActive = data?['lastSeen'] as Timestamp?;

                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 800),
                                child: AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 1000),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 8.r,
                                          spreadRadius: 2.r,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 60.r,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                      child: profilePic.isEmpty
                                          ? Icon(Icons.person, size: 60.sp, color: const Color(0xFF075E54))
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 1200),
                                child: Text(
                                  userName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF075E54),
                                      ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 1400),
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 1600),
                                child: Text(
                                  lastActive != null
                                      ? 'Last seen: ${lastActive.toDate().toString().substring(0, 16)}'
                                      : 'Last seen: Unknown',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 1800),
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed('/chat', arguments: {
                              'user': UserchatModel(
                                uid: userId,
                                name: userName,
                                email: email,
                                image: profilePic,
                                fcmToken: data?['fcmToken']?.toString() ?? '',
                                profilePic: profilePic,
                                lastActive: lastActive?.toDate(),
                              ),
                              'loggedInUserName': controller.cachedUserData['name']?.toString().trim() ?? 'Guest',
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF075E54),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                              elevation: 2,
                              shadowColor: Colors.grey.withOpacity(0.3),
                            ),
                            child: Text(
                              'Start Chat',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60.r,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 24.h),
            Container(
              width: 150.w,
              height: 24.h,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8.h),
            Container(
              width: 100.w,
              height: 16.h,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8.h),
            Container(
              width: 120.w,
              height: 14.h,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, AppController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60.sp,
            color: Colors.red.shade600,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.red.shade600,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Get.offNamed('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  elevation: 2,
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(userId).get();
                    Get.forceAppUpdate(); // Trigger rebuild
                  } catch (e) {
                    controller.showSnackBar('Error', 'Failed to retry: $e', Colors.red.shade600);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF075E54)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: const Color(0xFF075E54),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}