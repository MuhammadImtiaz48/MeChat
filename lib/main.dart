// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:imtiaz/views/auth/Signup.dart';
import 'package:imtiaz/views/auth/login.dart';
import 'package:imtiaz/views/auth/loginPhone.dart';
import 'package:imtiaz/firebase_Services/firebase_options.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:imtiaz/views/ui_screens/splash.dart';
import 'package:imtiaz/widgets/buttens.dart';

// ✅ Zego imports
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

// ✅ Global objects
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Zego credentials
const int zegoAppID = 116174848;
const String zegoAppSign =
    '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679';

// 🔔 Background FCM handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background Message: ${message.messageId}");
}

// 🔔 Show local notification
Future<void> _showLocalNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'mechat_channel_id',
    'MeChat Notifications',
    channelDescription: 'MeChat local notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Local notifications init
  await _initializeLocalNotification();

  // ✅ FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Foreground Message: ${message.notification?.title}");
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? "New Message",
        message.notification!.body ?? "You got a message",
      );
    }
  });

  // ✅ Notification tap (when app is opened by tapping notification)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("🔔 Notification tapped: ${message.data}");
    final receiverId = message.data['senderId'];
    if (receiverId != null && navigatorKey.currentContext != null) {
      Navigator.pushNamed(navigatorKey.currentContext!, '/chat',
          arguments: receiverId);
    }
  });

  // ✅ Setup Zego
  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
    [ZegoUIKitSignalingPlugin()],
  );
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await _initZego(currentUser);
  }

  runApp(const MyApp());
}

Future<void> _initializeLocalNotification() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mechat_channel_id',
    'MeChat Notifications',
    description: 'MeChat local notifications',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint("🔔 Local Notification tapped: ${response.payload}");
    },
  );
}

Future<void> _initZego(User user) async {
  await ZegoUIKitPrebuiltCallInvitationService().init(
    appID: zegoAppID,
    appSign: zegoAppSign,
    userID: user.uid,
    userName: user.displayName ?? user.email ?? "User-${user.uid.substring(0, 6)}",
    plugins: [ZegoUIKitSignalingPlugin()],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        home: const Splash(),
      ),
    );
  }
}

// ✅ Dashboard UI


class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF010147), Color(0xFF011220)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 40),
              // Animated Logo and Title
              _AnimatedLogoTitle(),
              SizedBox(height: 20),
              // Animated Headlines
              _AnimatedHeadlines(),
              SizedBox(height: 15),
              // Description Text
              _DescriptionText(),
              SizedBox(height: 30),
              // Social Login Buttons
              _SocialLoginButtons(context),
              SizedBox(height: 15),
              // Or Divider
              _OrDivider(),
              SizedBox(height: 20),
              // Sign Up Button
              _SignUpButton(context),
              SizedBox(height: 20),
              // Login Link
              _LoginLink(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoTitle extends StatefulWidget {
  @override
  __AnimatedLogoTitleState createState() => __AnimatedLogoTitleState();
}

class __AnimatedLogoTitleState extends State<_AnimatedLogoTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo with pulsing effect
            _PulsingLogo(),
            SizedBox(width: 20),
            Text(
              "MeChat",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.blueAccent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingLogo extends StatefulWidget {
  @override
  __PulsingLogoState createState() => __PulsingLogoState();
}

class __PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent,
              Colors.purpleAccent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.chat_bubble_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _AnimatedHeadlines extends StatefulWidget {
  @override
  __AnimatedHeadlinesState createState() => __AnimatedHeadlinesState();
}

class __AnimatedHeadlinesState extends State<_AnimatedHeadlines>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _slideAnimation1 = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation2 = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SlideTransition(
            position: _slideAnimation1,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                "Connect\nfriends",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          SlideTransition(
            position: _slideAnimation2,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                "easily & \n quickly",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.blueAccent.withOpacity(0.5),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        "Talk freely. Share instantly.\nWelcome to MeChat — your world, connected.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 16,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}

class _SocialLoginButtons extends StatefulWidget {
  final BuildContext context;
  
  _SocialLoginButtons(this.context);
  
  @override
  __SocialLoginButtonsState createState() => __SocialLoginButtonsState();
}

class __SocialLoginButtonsState extends State<_SocialLoginButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.2 * index, 0.2 * index + 0.6, curve: Curves.elasticOut),
        ),
      );
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Facebook Button
          ScaleTransition(
            scale: _animations[0],
            child: _SocialButton(
              icon: Image.asset('assets/images/facebook.png'),
              onPressed: () {
                // TODO: Facebook login
              },
            ),
          ),
          SizedBox(width: 20),
          // Google Button
          ScaleTransition(
            scale: _animations[1],
            child: _SocialButton(
              icon: Image.asset('assets/images/google.png'),
              onPressed: () async {
                bool isLoggedIn = await loginWithGoogle();
                if (isLoggedIn) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Login failed!"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(width: 20),
          // Phone Button
          ScaleTransition(
            scale: _animations[2],
            child: _SocialButton(
              icon: Icon(Icons.phone, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginphone()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  
  const _SocialButton({required this.icon, required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: icon,
        iconSize: 30,
        onPressed: onPressed,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.3),
              thickness: 1,
              indent: 40,
              endIndent: 10,
            ),
          ),
          Text(
            "OR",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.3),
              thickness: 1,
              indent: 10,
              endIndent: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpButton extends StatelessWidget {
  final BuildContext context;
  
  _SignUpButton(this.context);
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Signup()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: Text(
          "Sign up with email",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  final BuildContext context;
  
  _LoginLink(this.context);
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Existing account?",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(
              "Login",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> loginWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'image': user.photoURL ?? '',
        'fcmToken': fcmToken,
        'lastActive': DateTime.now(),
      }, SetOptions(merge: true));

      return true;
    }
    return false;
  } catch (e) {
    debugPrint("Login Error: $e");
    return false;
  }
}