import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/firebase_Services/firebase_options.dart';
import 'package:imtiaz/firebase_Services/notification_services.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/views/auth/Signup.dart';
import 'package:imtiaz/views/auth/login.dart';
import 'package:imtiaz/views/auth/login_phone.dart';
import 'package:imtiaz/views/ui_screens/chat_screen.dart';
import 'package:imtiaz/views/ui_screens/chat_screen_ai.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:imtiaz/views/ui_screens/splash.dart';
import 'package:imtiaz/views/ui_screens/user_profile.dart';
import 'package:imtiaz/views/ui_screens/users_list_screen.dart';
import 'package:imtiaz/payment/screens/wallet_screen.dart';
import 'package:imtiaz/payment/screens/payment_register_screen.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final data = message.data;
    final type = data['type'] ?? 'message';
    final chatId = data['chatId'] ?? '';
    final callId = data['callId'] ?? '';

    await NotificationService.showLocalNotification(
      id: type == 'call' ? callId.hashCode : chatId.hashCode,
      title: message.notification?.title ?? (type == 'call' ? 'Incoming Call' : 'New Message'),
      body: message.notification?.body ?? '',
      payload: jsonEncode(data), // Ensure payload is a JSON string
      type: type,
      chatId: chatId,
    );
    debugPrint('✅ Background notification handled: type=$type, chatId=$chatId');
  } catch (e) {
    debugPrint('❌ Background FCM handler error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 

  try {
    await _initializeFirebase();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await FirebaseMessaging.instance.requestPermission().timeout(const Duration(seconds: 10));

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final appController = Get.put(AppController(), permanent: true);

    await NotificationService.init(
      onNotificationTap: appController.handleNotificationTap,
    ).timeout(const Duration(seconds: 3), onTimeout: () {
      debugPrint('⚠️ NotificationService initialization timed out');
    });

    try {
      ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([ZegoUIKitSignalingPlugin()]);
      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
      debugPrint('✅ Zego UIKit initialized successfully');
    } catch (e) {
      debugPrint('❌ Zego UIKit initialization error: $e');
    }
  } catch (e) {
    debugPrint('❌ Main initialization error: $e');
    Get.snackbar(
      'Error',
      'Failed to initialize app: ${e.toString().split('.').first}',
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 10.r,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 4),
      isDismissible: true,
      titleText: Text(
        'Error',
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        'Failed to initialize app: ${e.toString().split('.').first}',
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Dismiss',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  for (int i = 0; i < 3; i++) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 5));
      debugPrint('✅ Firebase initialized successfully');
      return;
    } catch (e) {
      if (i == 2) {
        debugPrint('❌ Firebase initialization failed after retries: $e');
        throw Exception('Failed to initialize Firebase');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'MeChat',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF075E54),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF25D366),
          ),
          scaffoldBackgroundColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.black87),
            titleLarge: GoogleFonts.poppins(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF075E54)),
            bodySmall: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF075E54),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            brightness: Brightness.dark,
            secondary: const Color(0xFF25D366),
          ),
          scaffoldBackgroundColor: const Color(0xFF0B141A),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.white70),
            titleLarge: GoogleFonts.poppins(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF25D366)),
            bodySmall: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[400]),
          ),
        ),
        themeMode: ThemeMode.dark,
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(name: '/dashboard', page: () => const Dashboard()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/signup', page: () => const SignupScreen()),
          GetPage(name: '/phone_login', page: () => const Loginphone()),
          GetPage(
            name: '/home',
            page: () {
              final controller = Get.find<AppController>();
              return HomeScreen(userName: controller.cachedUserData['name']?.toString().trim() ?? 'Guest');
            },
          ),
          GetPage(name: '/users_list', page: () => const UsersListScreen()),
          GetPage(name: '/gemini_chat', page: () => const GeminiChatScreen()),
          GetPage(
            name: '/chat',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              final user = args?['user'] as UserchatModel? ??
                  UserchatModel(
                    uid: '',
                    name: 'Guest',
                    email: '',
                    image: '',
                    fcmToken: '',
                    profilePic: '',
                    lastActive: null,
                  );
              final loggedInUserName = args?['loggedInUserName']?.toString().trim() ?? 'Guest';
              return ChatScreen(
                user: user,
                loggedInUserName: loggedInUserName,
              );
            },
          ),
          GetPage(
            name: '/UserProfile',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              final user = args?['user'] as UserchatModel? ??
                  UserchatModel(
                    uid: '',
                    name: 'Guest',
                    email: '',
                    image: '',
                    fcmToken: '',
                    profilePic: '',
                    lastActive: null,
                  );
              final userId = args?['userId']?.toString() ?? '';
              final userName = args?['userName']?.toString().trim() ?? 'Guest';
              return UserProfileScreen(
                userId: userId,
                userName: userName,
                user: user,
              );
            },
          ),
          GetPage(name: '/wallet', page: () => const WalletScreen()),
          GetPage(name: '/payment_register', page: () => const PaymentRegisterScreen()),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 1000),
                  child: Icon(Icons.message, size: 80.sp, color: const Color(0xFF075E54)),
                ),
                SizedBox(height: 16.h),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 1200),
                  child: Text('MeChat', style: Theme.of(context).textTheme.titleLarge),
                ),
                SizedBox(height: 32.h),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 1400),
                  child: Text(
                    'Connect with friends easily & quickly',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 1600),
                  child: Text(
                    'Talk freely. Share instantly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                const _SocialLoginButtons(),
                SizedBox(height: 24.h),
                const _OrDivider(),
                SizedBox(height: 24.h),
                const _SignUpButton(),
                SizedBox(height: 16.h),
                const _LoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    return Obx(() => Stack(
          children: [
            Center(
              child: _SocialButton(
                icon: Image.asset('assets/images/google.png', width: 24.w),
                onPressed: controller.isLoading.value ? null : controller.loginWithGoogle,
              ),
            ),
            if (controller.isLoading.value)
              Container(
                color: Colors.black.withAlpha(128),
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF075E54),
                    strokeWidth: MediaQuery.of(context).size.width >= 600 ? 5.w : 4.w,
                  ),
                ),
              ),
          ],
        ));
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[300]!,
          width: 1.w,
        ),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        splashRadius: 28.w,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(color: Colors.grey[400], thickness: 1.w, indent: 40.w, endIndent: 10.w),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            'OR',
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey[400], thickness: 1.w, indent: 10.w, endIndent: 40.w),
        ),
      ],
    );
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Get.toNamed('/signup'),
      child: Text(
        'Sign up with email',
        style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Existing account?',
          style: GoogleFonts.poppins(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => Get.toNamed('/login'),
          child: Text(
            'Login',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF075E54),
              fontSize: 16.sp,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}