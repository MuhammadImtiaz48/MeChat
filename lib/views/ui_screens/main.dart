import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:imtiaz/auth/Signup.dart';
import 'package:imtiaz/auth/login.dart';
import 'package:imtiaz/auth/loginPhone.dart';
import 'package:imtiaz/firebase_Services/firebase_options.dart';
import 'package:imtiaz/ui_screens/home.dart';
import 'package:imtiaz/ui_screens/splash.dart';
import 'package:imtiaz/widgets/buttens.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 Background Message Received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initializeNotification();

  runApp(const MyApp());
}

Future<void> _initializeNotification() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  // Create notification channel for Android 8.0+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mechat_channel_id',
    'MeChat Notifications',
    description: 'This channel is used for MeChat notifications.',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        debugPrint('Notification payload tapped: ${response.payload}');
        // TODO: Implement navigation or logic here
      }
    },
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (Platform.isIOS) {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
      // Optionally show a dialog or UI prompt
    }
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("🔔 App opened from notification: ${message.notification?.title}");
    // TODO: Handle app open via notification
  });
}

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'mechat_channel_id',
    'MeChat Notifications',
    channelDescription: 'This channel is used for MeChat notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title ?? 'MeChat',
    message.notification?.body ?? '',
    notificationDetails,
    payload: message.data.toString(),
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
      builder: (_, __) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Splash(),
      ),
    );
  }
}

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
            colors: [
              Colors.black,
              Color(0xFF010147),
              Color(0xFF011220),
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/Subtract (1).png', scale: 0.9),
                SizedBox(width: 20.w),
                Text(
                  "MeChat",
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Text(
                    "Connect\nfriends",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 50.sp),
                  ),
                  Text(
                    "easily & \n quickly",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 45.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              "Talk freely. Share instantly.\nWelcome to MeChat — your world, connected.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 15.sp,
                color: const Color.fromARGB(103, 247, 248, 246),
              ),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/facebook.png'),
                    iconSize: 40.sp,
                    onPressed: () {
                      // TODO: Facebook login
                    },
                  ),
                  SizedBox(width: 20.w),
                  IconButton(
                    icon: Image.asset('assets/images/google.png'),
                    iconSize: 40.sp,
                    onPressed: () async {
                      bool isLoggedIn = await loginWithGoogle();
                      if (isLoggedIn) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Login failed!")),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 20.w),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.mobile_screen_share_rounded, color: Colors.blue),
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
            ),
            SizedBox(height: 15.h),
            Image.asset('assets/images/Or-uihut.png'),
            SizedBox(height: 20.h),
            Buttens(
              btname: "Sign up with email",
              textStyle: TextStyle(fontSize: 18.sp, color: Colors.black),
              callBack: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Signup()),
                );
              },
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Existing account?",
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
                SizedBox(width: 10.w),
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
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> loginWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
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