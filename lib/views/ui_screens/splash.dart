
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/controllers/splash_controller.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(AppController(), permanent: true);
    final SplashController controller = Get.put(SplashController());

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF075E54).withOpacity(0.15),
                const Color(0xFF25D366).withOpacity(0.05),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with scale, fade, and rotation
                  Obx(
                    () => AnimatedScale(
                      scale: controller.isLoading.value ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: controller.isLoading.value ? 1.0 : 0.8,
                        duration: const Duration(milliseconds: 1000),
                        child: AnimatedRotation(
                          turns: controller.isLoading.value ? 0 : -0.05,
                          duration: const Duration(milliseconds: 1200),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 10.r,
                                  spreadRadius: 3.r,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/chat.png',
                                width: 140.w,
                                height: 140.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Fade animation for app name with slight bounce
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 1400),
                    child: AnimatedSlide(
                      offset: const Offset(0, 0),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutBack,
                      child: Text(
                        'MeChat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 34.sp,
                              color: const Color(0xFF075E54),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Fade animation for tagline
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 1600),
                    child: Text(
                      'Connect with Friends Instantly',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Obx(() {
                    final isTablet = MediaQuery.of(context).size.width >= 600;
                    return Column(
                      children: [
                        if (controller.isLoading.value)
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        if (!controller.isOnline.value)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: Colors.orange.shade700, width: 1.w),
                              ),
                              child: Text(
                                'No Internet Connection',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.sp : 14.sp,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        if (controller.errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: Colors.red.shade600, width: 1.w),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: isTablet ? 24.sp : 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          controller.errorMessage.value,
                                          style: TextStyle(
                                            fontSize: isTablet ? 16.sp : 14.sp,
                                            color: Colors.red.shade600,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: controller.retry,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF075E54),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                        elevation: 2,
                                        shadowColor: Colors.grey.withOpacity(0.3),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    OutlinedButton(
                                      onPressed: () => Get.offNamed('/login'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF075E54)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                      ),
                                      child: Text(
                                        'Go to Login',
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
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
