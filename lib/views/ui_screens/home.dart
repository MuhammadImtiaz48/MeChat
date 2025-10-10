import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:imtiaz/controllers/home_screen_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/views/ui_screens/user_profile.dart';
import 'package:imtiaz/widgets/user_chat_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final HomeController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('HomeScreen: Initializing for userName=${widget.userName} at ${DateTime.now()}');
    }
    controller = Get.put(HomeController());
    _loadUserNameFromFirestore();
    _initializeConnectivity();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.loadUsers(); // Load sorted users on start
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  Future<void> _loadUserNameFromFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        if (snapshot.exists) {
          final name = snapshot.data()?['name']?.toString().trim() ?? '';
          String fallbackName = user.email?.split('@')[0] ?? 'User-${user.uid.substring(0, 6)}';
          final validName = name.isNotEmpty && name.toLowerCase() != 'unknown' ? name : fallbackName;
          controller.loggedInUserName.value = validName;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', validName);
          if (name != validName) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'name': validName,
              'lastActive': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            if (kDebugMode) {
              debugPrint('✅ HomeScreen: Fixed Firestore name to $validName for uid=${user.uid}');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ HomeScreen: User document not found for uid=${user.uid}');
          }
          String fallbackName = user.email?.split('@')[0] ?? 'User-${user.uid.substring(0, 6)}';
          controller.loggedInUserName.value = fallbackName;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', fallbackName);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': fallbackName,
            'email': user.email ?? '',
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (kDebugMode) {
            debugPrint('✅ HomeScreen: Set fallback name $fallbackName for uid=${user.uid}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ HomeScreen: Error loading user name: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        String cachedName = prefs.getString('user_name') ?? '';
        String fallbackName = user.email?.split('@')[0] ?? 'User-${user.uid.substring(0, 6)}';
        controller.loggedInUserName.value = cachedName.isNotEmpty && cachedName.toLowerCase() != 'unknown' ? cachedName : fallbackName;
        await prefs.setString('user_name', controller.loggedInUserName.value);
        if (kDebugMode) {
          debugPrint('✅ HomeScreen: Set name from cache or fallback: ${controller.loggedInUserName.value}');
        }
      }
    } else {
      controller.loggedInUserName.value = widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'unknown' ? widget.userName : 'User';
      if (kDebugMode) {
        debugPrint('⚠️ HomeScreen: No authenticated user, using fallback name: ${controller.loggedInUserName.value}');
      }
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 5));
      controller.isOnline.value = !connectivityResult.contains(ConnectivityResult.none);
      if (!controller.isOnline.value && mounted) {
        _showSnackBar('Offline', 'Showing cached data.', Colors.orange);
      }
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final isOnline = !results.contains(ConnectivityResult.none);
        if (controller.isOnline.value != isOnline) {
          controller.isOnline.value = isOnline;
          if (!isOnline && mounted) {
            _showSnackBar('Offline', 'Showing cached data.', Colors.orange);
          } else {
            // Reload users when back online for fresh sorted data
            controller.loadUsers();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Connectivity error: $e');
      }
      controller.isOnline.value = false;
      if (mounted) {
        _showSnackBar('Error', 'Unable to check network connection', Colors.red);
      }
    }
  }

  void _showSnackBar(String title, String message, Color backgroundColor) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 10.r,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 3),
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAllNamed('/dashboard');
      if (kDebugMode) {
        debugPrint('✅ HomeScreen: User logged out at ${DateTime.now()}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Logout error: $e');
      }
      if (mounted) {
        _showSnackBar('Error', 'Logout failed: $e', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('HomeScreen: Disposing at ${DateTime.now()}');
    }
    _connectivitySubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isTablet = screenWidth >= 600;
        final isSmallScreen = screenWidth < 360;
        final isTallScreen = screenHeight > 750;
        final fontSizeTitle = isSmallScreen ? 18.sp : isTablet ? 24.sp : 20.sp;
        final fontSizeSubtitle = isSmallScreen ? 12.sp : isTablet ? 16.sp : 14.sp;
        final paddingHorizontal = isSmallScreen ? 12.w : isTablet ? 24.w : 16.w;
        final paddingVertical = isTablet ? 16.h : 12.h;
        final iconSize = isSmallScreen ? 20.w : isTablet ? 28.w : 24.w;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isTablet ? 80.h : isTallScreen ? 64.h : 56.h),
            child: AppBar(
              backgroundColor: const Color(0xFF075E54),
              elevation: 0,
              toolbarHeight: isTablet ? 80.h : isTallScreen ? 64.h : 56.h,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF075E54), Color.fromARGB(255, 37, 224, 202)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Text(
                'MeChat',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.menu, color: Colors.white, size: iconSize),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: Colors.white, size: iconSize),
                  onPressed: () {
                    controller.isSearching.value = !controller.isSearching.value;
                    if (!controller.isSearching.value) {
                      controller.clearSearch();
                    }
                  },
                  tooltip: 'Search',
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF075E54), Color(0xFF075E54)],
                ),
              ),
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Obx(() {
                      final displayName = controller.loggedInUserName.value.isNotEmpty
                          ? controller.loggedInUserName.value
                          : widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'unknown'
                              ? widget.userName
                              : 'User';
                      return Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                    accountEmail: Text(
                      _auth.currentUser?.email ?? 'No email',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeSubtitle,
                        color: Colors.white70,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      radius: isTablet ? 40.r : 30.r,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _auth.currentUser?.photoURL != null
                          ? NetworkImage(_auth.currentUser!.photoURL!)
                          : null,
                      child: _auth.currentUser?.photoURL == null
                          ? Obx(() {
                              final displayName = controller.loggedInUserName.value.isNotEmpty
                                  ? controller.loggedInUserName.value
                                  : widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'unknown'
                                      ? widget.userName
                                      : 'User';
                              return Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 30.sp : 24.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            })
                          : null,
                    ),
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                  ListTile(
                    leading: Icon(Icons.person, size: iconSize, color: Colors.white),
                    title: Text(
                      'Profile',
                      style: GoogleFonts.poppins(fontSize: fontSizeSubtitle, color: Colors.white),
                    ),
                    onTap: () async {
                      Get.back(); // Close drawer
                      try {
                        UserchatModel userProfile;
                        if (controller.isOnline.value) {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(_auth.currentUser!.uid)
                              .get()
                              .timeout(const Duration(seconds: 5));
                          if (!userDoc.exists) {
                            throw Exception('User profile not found');
                          }
                          userProfile = UserchatModel.fromMap(userDoc.data()!);
                        } else {
                          final prefs = await SharedPreferences.getInstance();
                          userProfile = UserchatModel(
                            uid: _auth.currentUser!.uid,
                            name: prefs.getString('user_name') ?? (_auth.currentUser!.email?.split('@')[0] ?? 'User-${_auth.currentUser!.uid.substring(0, 6)}'),
                            email: prefs.getString('user_email') ?? '',
                            image: '',
                            fcmToken: prefs.getString('user_fcmToken') ?? '',
                            profilePic: prefs.getString('user_profilePic') ?? '',
                          );
                        }
                        Get.to(() => UserProfileScreen(user: userProfile, userId: userProfile.uid, userName: userProfile.name));
                      } catch (e) {
                        _showSnackBar(
                          'Error',
                          'Failed to load profile: ${controller.isOnline.value ? e.toString().split('.').first : 'Offline mode'}',
                          Colors.red,
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, size: iconSize, color: Colors.white),
                    title: Text(
                      'Logout',
                      style: GoogleFonts.poppins(fontSize: fontSizeSubtitle, color: Colors.white),
                    ),
                    onTap: () {
                      Get.back(); // Close drawer
                      Get.dialog(
                        AlertDialog(
                          title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back(); // Close dialog
                                _logout();
                              },
                              child: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFF075E54)],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    Obx(() => !controller.isOnline.value
                        ? Container(
                            color: Colors.orange[100],
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            child: Center(
                              child: Text(
                                'Offline: Showing cached data',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSizeSubtitle,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                    Obx(() => controller.isSearching.value
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: paddingHorizontal,
                              vertical: paddingVertical,
                            ),
                            child: TextField(
                              controller: controller.searchController,
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: fontSizeSubtitle,
                                  color: Colors.grey[600],
                                ),
                                prefixIcon: Icon(Icons.search, size: iconSize, color: const Color(0xFF075E54)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(color: Color(0xFF075E54), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                suffixIcon: controller.searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, size: iconSize, color: Colors.grey[600]),
                                        onPressed: controller.clearSearch,
                                      )
                                    : null,
                              ),
                              style: GoogleFonts.poppins(fontSize: fontSizeSubtitle),
                              onChanged: (value) => controller.filterUsers(value),
                            ),
                          )
                        : const SizedBox.shrink()),
                    Expanded(
                      child: Obx(() {
                        if (controller.loadingUsers.value) {
                          return _buildLoadingState(isTablet, fontSizeSubtitle);
                        }
                        if (controller.filteredUsers.isEmpty && controller.isOnline.value) {
                          return Column(
                            children: [
                              _buildGeminiCard(context, isTablet, fontSizeSubtitle, iconSize),
                              Expanded(child: _buildEmptyState(isTablet, fontSizeSubtitle, controller)),
                            ],
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            vertical: paddingVertical,
                            horizontal: paddingHorizontal,
                          ),
                          itemCount: controller.filteredUsers.length + 1, // +1 for Gemini AI card
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildGeminiCard(context, isTablet, fontSizeSubtitle, iconSize);
                            }
                            final userIndex = index - 1;
                            if (userIndex >= controller.filteredUsers.length) {
                              return const SizedBox.shrink(); // Prevent index out of range
                            }
                            final user = controller.filteredUsers[userIndex];
                            if (user.uid.isEmpty) {
                              return const SizedBox.shrink(); // Skip invalid users
                            }
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: UserChatCard(
                                user: user,
                                onTap: () {
                                  Get.toNamed(
                                    '/chat',
                                    arguments: {
                                      'user': user,
                                      'loggedInUserName': controller.loggedInUserName.value.isNotEmpty
                                          ? controller.loggedInUserName.value
                                          : widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'unknown'
                                              ? widget.userName
                                              : 'User',
                                    },
                                  );
                                },
                                loggedInUserName: controller.loggedInUserName.value.isNotEmpty
                                    ? controller.loggedInUserName.value
                                    : widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'unknown'
                                        ? widget.userName
                                        : 'User',
                                currentUserId: _auth.currentUser?.uid ?? '',
                                senderId: '',
                                senderName: '',
                                message: '',
                                time: null,
                                seen: null,
                                showSeen: null,
                                maxWidth: null,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeminiCard(BuildContext context, bool isTablet, double fontSizeSubtitle, double iconSize) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: controller.isOnline.value
            ? () {
                Get.toNamed('/gemini_chat');
              }
            : () {
                _showSnackBar('Offline', 'AI chat requires internet connection', Colors.orange);
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: controller.isOnline.value
                  ? [const Color(0xFF075E54), const Color.fromARGB(255, 73, 216, 199)]
                  : [Colors.grey[400]!, Colors.grey[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: isTablet ? 24.r : 20.r,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.smart_toy,
                color: const Color(0xFF075E54),
                size: isTablet ? 28.w : 24.w,
              ),
            ),
            title: Text(
              'MeChat AI',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 18.sp : 16.sp,
              ),
            ),
            subtitle: Text(
              controller.isOnline.value ? 'Chat with our AI assistant' : 'Offline - Connect to use AI',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: fontSizeSubtitle,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: isTablet ? 18.w : 16.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet, double fontSizeSubtitle) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              height: 70.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6.r,
                    spreadRadius: 1.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    margin: EdgeInsets.all(8.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120.w,
                          height: 16.h,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 80.w,
                          height: 12.h,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, double fontSizeSubtitle, HomeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: isTablet ? 80.w : 60.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No chats found',
            style: GoogleFonts.poppins(
              fontSize: fontSizeSubtitle,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (controller.isOnline.value) ...[
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: () => controller.loadUsers(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF075E54)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeSubtitle,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF075E54),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}