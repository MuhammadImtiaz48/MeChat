import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/views/ui_screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:imtiaz/models/userchat.dart';

const int zegoAppID = 1594596596;
const String zegoAppSign = '305434fc77fd131fb25e505218b60d4caa5e46cea28f1533363190df19e39dd4';

class AppController extends GetxController {
  final RxBool isOnline = true.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxMap<String, String> cachedUserData = RxMap<String, String>({});
  final Rx<UserchatModel?> currentUserModel = Rx<UserchatModel?>(null);
  final RxBool isZegoInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _checkConnectivity();
      currentUser.value = FirebaseAuth.instance.currentUser;
      if (currentUser.value != null) {
        await _loadCachedUserData();
        await saveUserToFirestore(currentUser.value!);
        await _initZego(currentUser.value!);
      }
    } catch (e) {
      debugPrint('❌ AppController: Initialization error: $e');
      errorMessage.value = 'Failed to initialize app';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 10));
      isOnline.value = !connectivityResult.contains(ConnectivityResult.none);
      if (!isOnline.value) {
        errorMessage.value = 'Offline: Limited functionality available';
        showSnackBar('Offline', errorMessage.value, Colors.orange.shade600);
      }
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        isOnline.value = !results.contains(ConnectivityResult.none);
        if (!isOnline.value) {
          errorMessage.value = 'Offline: Limited functionality available';
          showSnackBar('Offline', errorMessage.value, Colors.orange.shade600);
        }
      });
    } catch (e) {
      debugPrint('❌ AppController: Connectivity check error: $e');
      isOnline.value = false;
      errorMessage.value = 'Connectivity check failed';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      if (!isOnline.value) {
        errorMessage.value = 'Please connect to the internet to sign in';
        showSnackBar('Offline', errorMessage.value, Colors.red.shade600);
        return;
      }

      // Google Sign-In is disabled for now due to API changes
      errorMessage.value = 'Google Sign-In is temporarily unavailable';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
      return;

      // Commented out the problematic code
      /*
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In cancelled by user');
        return;
      }

      final googleAuth = await googleUser.authentication.timeout(const Duration(seconds: 10));
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 5));

      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!);
        await _cacheUserData(userCredential.user!);
        await _initZego(userCredential.user!);
        currentUser.value = userCredential.user;
        debugPrint('✅ Google Sign-In successful: uid=${userCredential.user?.uid}');
        Get.offAllNamed(
          '/home',
          arguments: {'userName': cachedUserData['name'] ?? userCredential.user!.email!.split('@')[0]},
        );
      }
      */
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      errorMessage.value = 'Google Sign-In failed: ${e.toString().split('.').first}';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_uid');
      if (uid != null) {
        String name = prefs.getString('user_name') ?? '';
        if (name.isEmpty || name.toLowerCase() == 'unknown') {
          name = currentUser.value?.email?.split('@')[0] ?? 'User-$uid';
          await prefs.setString('user_name', name);
          debugPrint('✅ AppController: Fixed invalid cached name to $name for uid=$uid');
        }
        cachedUserData.assignAll({
          'uid': uid,
          'name': name,
          'email': prefs.getString('user_email') ?? '',
          'profilePic': prefs.getString('user_profilePic') ?? '',
          'fcmToken': prefs.getString('user_fcmToken') ?? '',
        });
        currentUserModel.value = UserchatModel(
          uid: uid,
          name: name,
          email: cachedUserData['email']!,
          image: cachedUserData['profilePic']!,
          fcmToken: cachedUserData['fcmToken']!,
          profilePic: '',
        );
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ AppController: Loaded cached user data: uid=$uid, name=$name');
      }
    } catch (e) {
      debugPrint('❌ AppController: Load cached user data error: $e');
    }
  }

  Future<void> saveUserToFirestore(User user) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      String name = user.displayName?.trim() ??
          user.email?.split('@')[0] ??
          'User-${user.uid.substring(0, 6)}';
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name');
      if (cachedName != null && cachedName.isNotEmpty && cachedName.toLowerCase() != 'unknown') {
        name = cachedName;
        debugPrint('✅ AppController: Using cached name: $name for uid=${user.uid}');
      }
      final userModel = UserchatModel(
        uid: user.uid,
        name: name,
        email: user.email ?? '',
        image: user.photoURL ?? '',
        fcmToken: fcmToken ?? '',
        profilePic: '',
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      currentUserModel.value = userModel;
      await prefs.setString('user_name', name);
      debugPrint('✅ AppController: User saved to Firestore: uid=${user.uid}, name=$name');
    } catch (e) {
      debugPrint('❌ AppController: Failed to save user to Firestore: $e');
      errorMessage.value = 'Failed to save user data';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
    }
  }

  Future<void> _initZego(User user) async {
    for (int i = 0; i < 3; i++) {
      try {
        if (!isOnline.value) {
          debugPrint('⚠️ AppController: Offline, skipping Zego initialization');
          errorMessage.value = 'Call services unavailable offline';
          showSnackBar('Offline', errorMessage.value, Colors.orange.shade600);
          isZegoInitialized.value = false;
          return;
        }

        String name = user.displayName?.trim() ??
            user.email?.split('@')[0] ??
            'User-${user.uid.substring(0, 6)}';
        final prefs = await SharedPreferences.getInstance();
        final cachedName = prefs.getString('user_name');
        if (cachedName != null && cachedName.isNotEmpty && cachedName.toLowerCase() != 'unknown') {
          name = cachedName;
        }
        await ZegoUIKitPrebuiltCallInvitationService().init(
          appID: zegoAppID,
          appSign: zegoAppSign,
          userID: user.uid,
          userName: name,
          plugins: [ZegoUIKitSignalingPlugin()],
          notificationConfig: ZegoCallInvitationNotificationConfig(
            androidNotificationConfig: ZegoCallAndroidNotificationConfig(
              callChannel: ZegoCallAndroidNotificationChannelConfig(
                channelID: 'ZegoCall',
                channelName: 'Call Notifications',
                sound: 'ringtone',
                icon: 'notification_icon',
                vibrate: true,
              ),
            ),
          ),
        ).timeout(const Duration(seconds: 15));
        isZegoInitialized.value = true;
        debugPrint('✅ AppController: Zego initialized for user: uid=${user.uid}, name=$name');
        return;
      } catch (e) {
        debugPrint('❌ AppController: Zego initialization attempt ${i + 1} failed: $e');
        if (i == 2) {
          errorMessage.value = 'Failed to initialize call services';
          showSnackBar('Error', errorMessage.value, Colors.red.shade600);
          isZegoInitialized.value = false;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    try {
      final type = data['type'] ?? 'message';
      final senderId = data['senderId'];
      final chatId = data['chatId'] ?? '';
      final callId = data['callId'] ?? '';

      if (senderId == null || currentUser.value == null) {
        debugPrint('⚠️ AppController: Invalid notification data: senderId=$senderId, type=$type');
        return;
      }

      // For payments, chatId can be empty
      if (type != 'payment' && chatId.isEmpty) {
        debugPrint('⚠️ AppController: Invalid notification data: chatId is empty for non-payment type');
        return;
      }

      await _checkConnectivity();
      String loggedInUserName = cachedUserData['name'] ?? '';
      if (loggedInUserName.isEmpty || loggedInUserName.toLowerCase() == 'unknown') {
        loggedInUserName = currentUser.value!.email?.split('@')[0] ?? 'User-${currentUser.value!.uid.substring(0, 6)}';
        await FirebaseFirestore.instance.collection('users').doc(currentUser.value!.uid).set({
          'name': loggedInUserName,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        cachedUserData['name'] = loggedInUserName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', loggedInUserName);
        debugPrint('✅ AppController: Fixed loggedInUserName to $loggedInUserName');
      }
      if (isOnline.value) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.value!.uid)
            .get()
            .timeout(const Duration(seconds: 3));
        if (userDoc.exists && userDoc['name']!.toString().trim().isNotEmpty && userDoc['name'].toString().toLowerCase() != 'unknown') {
          loggedInUserName = userDoc['name'];
          cachedUserData['name'] = loggedInUserName;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', loggedInUserName);
        }
      }

      UserchatModel user;
      if (isOnline.value) {
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get()
            .timeout(const Duration(seconds: 3));
        if (!senderDoc.exists) {
          debugPrint('⚠️ AppController: Sender not found: senderId=$senderId');
          return;
        }
        final userData = senderDoc.data()!;
        user = UserchatModel.fromMap(userData);
      } else {
        user = UserchatModel(
          uid: senderId,
          name: 'User-${senderId.substring(0, 6)}',
          email: '',
          image: '',
          fcmToken: '',
          profilePic: '',
        );
        errorMessage.value = 'Limited functionality available offline';
        showSnackBar('Offline', errorMessage.value, Colors.orange.shade600);
      }

      if (type == 'message') {
        debugPrint('🚀 AppController: Navigating to ChatScreen: uid=$senderId');
        Get.toNamed(
          '/chat',
          arguments: {
            'user': user,
            'loggedInUserName': loggedInUserName,
          },
        );
      } else if (type == 'call') {
        if (isOnline.value) {
          debugPrint('🚀 AppController: Call notification tapped: callId=$callId');
          // For call notifications from terminated/background state,
          // since the call might not be active anymore, navigate to chat
          // In a production app, you'd check if the call is still active
          Get.toNamed(
            '/chat',
            arguments: {
              'user': UserchatModel(
                uid: senderId,
                name: 'Unknown', // Would need to fetch from Firestore
                email: '',
                image: '',
                fcmToken: '',
                profilePic: '',
              ),
              'loggedInUserName': loggedInUserName,
            },
          );
        } else {
          errorMessage.value = 'Cannot initiate calls while offline';
          showSnackBar('Offline', errorMessage.value, Colors.red.shade600);
        }
      } else if (type == 'payment') {
        debugPrint('🚀 AppController: Payment notification tapped');
        // Navigate to wallet screen to show payment details
        Get.toNamed('/wallet');
      }
    } catch (e) {
      debugPrint('❌ AppController: Notification tap error: $e');
      errorMessage.value = 'Failed to handle notification';
      showSnackBar('Error', errorMessage.value, Colors.red.shade600);
    }
  }

  void showSnackBar(String title, String message, Color backgroundColor) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 10.r,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 3),
      titleText: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
      mainButton: TextButton(
        onPressed: () => Get.closeAllSnackbars(),
        child: const Text(
          'Dismiss',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> handleNotificationNavigation(String? chatUserId) async {
    try {
      debugPrint('AppController: Handling notification for user $chatUserId');
      if (chatUserId != null && chatUserId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(chatUserId).get();
        if (userDoc.exists) {
          final userModel = UserchatModel.fromMap(userDoc.data()!);
          String loggedInUserName = cachedUserData['name'] ?? '';
          if (loggedInUserName.isEmpty || loggedInUserName.toLowerCase() == 'unknown') {
            loggedInUserName = currentUser.value!.email?.split('@')[0] ?? 'User-${currentUser.value!.uid.substring(0, 6)}';
            cachedUserData['name'] = loggedInUserName;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', loggedInUserName);
            await FirebaseFirestore.instance.collection('users').doc(currentUser.value!.uid).set({
              'name': loggedInUserName,
              'lastActive': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            debugPrint('✅ AppController: Fixed loggedInUserName to $loggedInUserName');
          }
          Get.to(() => ChatScreen(
                user: userModel,
                loggedInUserName: loggedInUserName,
              ));
        } else {
          debugPrint('❌ AppController: User $chatUserId not found');
          showSnackBar('Error', 'User not found', Colors.red.shade600);
        }
      }
    } catch (e) {
      debugPrint('❌ AppController: Notification navigation error: $e');
      showSnackBar('Error', 'Failed to open chat', Colors.red.shade600);
    }
  }
}