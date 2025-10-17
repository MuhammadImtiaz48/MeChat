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
    _initializeController();
    _initializeAnimations();
    _loadUserNameFromFirestore();
    _initializeConnectivity();
  }

  void _initializeController() {
    controller = Get.put(HomeController());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.loadUsers();
    });
  }

  void _initializeAnimations() {
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
    if (user == null) {
      _setFallbackUserName();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
          
      await _processUserSnapshot(snapshot, user);
    } catch (e) {
      await _handleUserNameError(user, e);
    }
  }

  Future<void> _processUserSnapshot(DocumentSnapshot snapshot, User user) async {
    if (snapshot.exists) {
      await _handleExistingUser(snapshot, user);
    } else {
      await _handleNewUser(user);
    }
  }

  Future<void> _handleExistingUser(DocumentSnapshot snapshot, User user) async {
    final processedName = await _processUserName(snapshot, user);
    controller.loggedInUserName.value = processedName;
    await _cacheUserName(processedName);
  }

  Future<String> _processUserName(DocumentSnapshot snapshot, User user) async {
    final data = snapshot.data() as Map<String, dynamic>?;
    final rawName = data?['name']?.toString().trim() ?? '';
    final fallbackName = _getFallbackName(user);
    final validName = _validateName(rawName, fallbackName);

    if (rawName != validName) {
      await _updateFirestoreName(user.uid, validName);
    }

    return validName;
  }

  Future<void> _handleNewUser(User user) async {
    final fallbackName = _getFallbackName(user);
    controller.loggedInUserName.value = fallbackName;
    await _cacheUserName(fallbackName);
    await _createUserDocument(user, fallbackName);
  }

  Future<void> _handleUserNameError(User user, Object error) async {
    if (kDebugMode) {
      debugPrint('User name loading error: $error');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_name') ?? '';
    final fallbackName = _getFallbackName(user);
    
    controller.loggedInUserName.value = _validateName(cachedName, fallbackName);
    await _cacheUserName(controller.loggedInUserName.value);
  }

  void _setFallbackUserName() {
    controller.loggedInUserName.value = _validateName(widget.userName, 'User');
  }

  String _getFallbackName(User user) {
    return user.email?.split('@')[0] ?? 'User-${user.uid.substring(0, 6)}';
  }

  String _validateName(String name, String fallback) {
    return name.isNotEmpty && name.toLowerCase() != 'unknown' ? name : fallback;
  }

  Future<void> _cacheUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  Future<void> _updateFirestoreName(String uid, String name) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _createUserDocument(User user, String name) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email ?? '',
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _initializeConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 5));
      _updateConnectivityStatus(connectivityResult);
      
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    } catch (e) {
      _handleConnectivityError(e);
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    controller.isOnline.value = isOnline;
    
    if (!isOnline && mounted) {
      _showSnackBar('Offline', 'Showing cached data.', Colors.orange);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    
    if (controller.isOnline.value != isOnline) {
      controller.isOnline.value = isOnline;
      
      if (!isOnline && mounted) {
        _showSnackBar('Offline', 'Showing cached data.', Colors.orange);
      } else {
        controller.loadUsers();
      }
    }
  }

  void _handleConnectivityError(Object error) {
    if (kDebugMode) {
      debugPrint('Connectivity error: $error');
    }
    
    controller.isOnline.value = false;
    if (mounted) {
      _showSnackBar('Error', 'Unable to check network connection', Colors.red);
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
    } catch (e) {
      _showSnackBar('Error', 'Logout failed: ${e.toString()}', Colors.red);
    }
  }

  void _confirmLogout() {
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
              Get.back();
              _logout();
            },
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width >= 600;
        final isSmallScreen = screenSize.width < 360;
        final isTallScreen = screenSize.height > 750;
        
        final layoutMetrics = _LayoutMetrics(
          isTablet: isTablet,
          isSmallScreen: isSmallScreen,
          isTallScreen: isTallScreen,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: _buildAppBar(layoutMetrics),
          drawer: _buildDrawer(layoutMetrics),
          body: _buildBody(layoutMetrics),
          floatingActionButton: _buildFloatingActionButton(layoutMetrics),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(_LayoutMetrics metrics) {
    return PreferredSize(
      preferredSize: Size.fromHeight(metrics.appBarHeight),
      child: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        toolbarHeight: metrics.appBarHeight,
        title: Text(
          'MeChat',
          style: GoogleFonts.poppins(
            fontSize: metrics.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: metrics.iconSize),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: metrics.iconSize),
            onPressed: _toggleSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: metrics.iconSize,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: metrics.iconSize),
            onPressed: () => _showAppBarMenu(),
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  void _showAppBarMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        PopupMenuItem(
          value: 'settings',
          child: Text('Settings', style: GoogleFonts.poppins()),
        ),
        PopupMenuItem(
          value: 'help',
          child: Text('Help', style: GoogleFonts.poppins()),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        _showSnackBar('Settings', 'Feature coming soon!', Colors.blue);
      } else if (value == 'help') {
        _showSnackBar('Help', 'Contact support for assistance', Colors.blue);
      }
    });
  }

  void _toggleSearch() {
    controller.isSearching.value = !controller.isSearching.value;
    if (!controller.isSearching.value) {
      controller.clearSearch();
    }
  }

  void _toggleTheme() {
    Get.changeThemeMode(
      Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Widget _buildDrawer(_LayoutMetrics metrics) {
    return Drawer(
      child: Container(
        color: const Color(0xFF075E54),
        child: Column(
          children: [
            _buildDrawerHeader(metrics),
            _buildDrawerMenuItems(metrics),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(_LayoutMetrics metrics) {
    return UserAccountsDrawerHeader(
      accountName: Obx(() => Text(
        _getDisplayName(),
        style: GoogleFonts.poppins(
          fontSize: metrics.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )),
      accountEmail: Text(
        _auth.currentUser?.email ?? 'No email',
        style: GoogleFonts.poppins(
          fontSize: metrics.fontSizeSubtitle,
          color: Colors.white70,
        ),
      ),
      currentAccountPicture: _buildUserAvatar(metrics),
      decoration: const BoxDecoration(color: Colors.transparent),
    );
  }

  String _getDisplayName() {
    final controllerName = controller.loggedInUserName.value;
    final widgetName = widget.userName;
    
    if (controllerName.isNotEmpty) return controllerName;
    if (widgetName.isNotEmpty && widgetName.toLowerCase() != 'unknown') return widgetName;
    return 'User';
  }

  Widget _buildUserAvatar(_LayoutMetrics metrics) {
    return CircleAvatar(
      radius: metrics.avatarRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: _auth.currentUser?.photoURL != null
          ? NetworkImage(_auth.currentUser!.photoURL!)
          : null,
      child: _auth.currentUser?.photoURL == null
          ? Obx(() => Text(
                _getDisplayName().isNotEmpty ? _getDisplayName()[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: metrics.avatarFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ))
          : null,
    );
  }

  Widget _buildDrawerMenuItems(_LayoutMetrics metrics) {
    return Column(
      children: [
        _buildDrawerTile(
          icon: Icons.person,
          title: 'Profile',
          onTap: _navigateToProfile,
          metrics: metrics,
        ),
        _buildDrawerTile(
          icon: Icons.logout,
          title: 'Logout',
          onTap: _confirmLogout,
          metrics: metrics,
        ),
      ],
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required _LayoutMetrics metrics,
  }) {
    return ListTile(
      leading: Icon(icon, size: metrics.iconSize, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: metrics.fontSizeSubtitle, color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  Future<void> _navigateToProfile() async {
    Get.back();
    try {
      final userProfile = await _loadUserProfile();
      Get.to(() => UserProfileScreen(
        user: userProfile,
        userId: userProfile.uid,
        userName: userProfile.name,
      ));
    } catch (e) {
      _showSnackBar(
        'Error',
        'Failed to load profile: ${controller.isOnline.value ? e.toString().split('.').first : 'Offline mode'}',
        Colors.red,
      );
    }
  }

  Future<UserchatModel> _loadUserProfile() async {
    if (controller.isOnline.value) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 5));
          
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      return UserchatModel.fromMap(userDoc.data()!);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return UserchatModel(
        uid: _auth.currentUser!.uid,
        name: prefs.getString('user_name') ?? 
              (_auth.currentUser!.email?.split('@')[0] ?? 
              'User-${_auth.currentUser!.uid.substring(0, 6)}'),
        email: prefs.getString('user_email') ?? '',
        image: '',
        fcmToken: prefs.getString('user_fcmToken') ?? '',
        profilePic: prefs.getString('user_profilePic') ?? '',
      );
    }
  }

  Widget _buildBody(_LayoutMetrics metrics) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFECE5DD),
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  _buildOfflineBanner(metrics),
                  _buildSearchField(metrics),
                ],
              ),
            ),
          ),
          _buildUserList(metrics),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(_LayoutMetrics metrics) {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/users_list'),
      backgroundColor: const Color(0xFF25D366),
      tooltip: 'New Chat',
      child: Icon(
        Icons.chat,
        color: Colors.white,
        size: metrics.iconSize * 0.8,
      ),
    );
  }

  Widget _buildOfflineBanner(_LayoutMetrics metrics) {
    return Obx(() => !controller.isOnline.value
        ? Container(
            color: Colors.orange[100],
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Center(
              child: Text(
                'Offline: Showing cached data',
                style: GoogleFonts.poppins(
                  fontSize: metrics.fontSizeSubtitle,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildSearchField(_LayoutMetrics metrics) {
    return Obx(() => controller.isSearching.value
        ? Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : const Color(0xFFECE5DD),
            padding: EdgeInsets.symmetric(
              horizontal: metrics.paddingHorizontal,
              vertical: metrics.paddingVertical,
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: metrics.fontSizeSubtitle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: metrics.iconSize,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[500],
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: metrics.iconSize, color: Colors.grey[600]),
                        onPressed: controller.clearSearch,
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(
                fontSize: metrics.fontSizeSubtitle,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
              onChanged: (value) => controller.filterUsers(value),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildUserList(_LayoutMetrics metrics) {
    return Expanded(
      child: Obx(() {
        if (controller.loadingUsers.value) {
          return _buildLoadingState(metrics);
        }

        if (controller.filteredUsers.isEmpty && controller.isOnline.value) {
          return Column(
            children: [
              _buildGeminiCard(metrics),
              Expanded(child: _buildEmptyState(metrics)),
            ],
          );
        }

        return _buildUserListView(metrics);
      }),
    );
  }

  Widget _buildUserListView(_LayoutMetrics metrics) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.filteredUsers.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildGeminiCard(metrics);
        }

        final userIndex = index - 1;
        if (userIndex >= controller.filteredUsers.length) {
          return const SizedBox.shrink();
        }

        final user = controller.filteredUsers[userIndex];
        if (user.uid.isEmpty) {
          return const SizedBox.shrink();
        }

        return UserChatCard(
          user: user,
          onTap: () => _navigateToChat(user),
          onLongPress: () => _showDeleteDialog(user),
          onAvatarTap: () => _navigateToUserProfile(user),
          loggedInUserName: _getDisplayName(),
          currentUserId: _auth.currentUser?.uid ?? '',
          senderId: '',
          senderName: '',
          message: '',
          time: null,
          seen: null,
          showSeen: null,
          maxWidth: null,
        );
      },
    );
  }

  void _navigateToChat(UserchatModel user) {
    Get.toNamed(
      '/chat',
      arguments: {
        'user': user,
        'loggedInUserName': _getDisplayName(),
      },
    );
  }

  void _showDeleteDialog(UserchatModel user) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete the chat with ${user.name}?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteChat(user);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(UserchatModel user) async {
    try {
      // Add to deleted users list
      controller.deletedUserIds.add(user.uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('deleted_user_ids', controller.deletedUserIds.toList());

      // Remove from local lists
      controller.filteredUsers.removeWhere((u) => u.uid == user.uid);
      controller.allUsers.removeWhere((u) => u.uid == user.uid);

      // Delete from Firestore if online
      if (controller.isOnline.value) {
        // Find and delete the chat document
        final chatQuery = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _auth.currentUser!.uid)
            .get();

        for (var doc in chatQuery.docs) {
          final participants = List<String>.from(doc.data()['participants'] ?? []);
          if (participants.contains(user.uid)) {
            await doc.reference.delete();
            break;
          }
        }
      }

      _showSnackBar('Success', 'Chat deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error', 'Failed to delete chat: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _navigateToUserProfile(UserchatModel user) async {
    try {
      Get.to(() => UserProfileScreen(
        user: user,
        userId: user.uid,
        userName: user.name,
      ));
    } catch (e) {
      _showSnackBar(
        'Error',
        'Failed to load profile: ${controller.isOnline.value ? e.toString().split('.').first : 'Offline mode'}',
        Colors.red,
      );
    }
  }

  Widget _buildGeminiCard(_LayoutMetrics metrics) {
    return GestureDetector(
      onTap: controller.isOnline.value
          ? () => Get.toNamed('/gemini_chat')
          : () => _showSnackBar('Offline', 'AI chat requires internet connection', Colors.orange),
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFECE5DD),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: controller.isOnline.value ? const Color(0xFF075E54) : Colors.grey[400],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: metrics.isTablet ? 24.r : 20.r,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.smart_toy,
                    color: const Color(0xFF075E54),
                    size: metrics.isTablet ? 28.w : 24.w,
                  ),
                ),
                title: Text(
                  'MeChat AI',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: metrics.isTablet ? 18.sp : 16.sp,
                  ),
                ),
                subtitle: Text(
                  controller.isOnline.value ? 'Chat with our AI assistant' : 'Offline - Connect to use AI',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: metrics.fontSizeSubtitle,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: metrics.isTablet ? 18.w : 16.w,
                ),
              ),
            ),
            Container(
              height: 1.h,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300],
              margin: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(_LayoutMetrics metrics) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFECE5DD),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]!
            : Colors.grey[200]!,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]!
            : Colors.grey[100]!,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(_LayoutMetrics metrics) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFECE5DD),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: metrics.isTablet ? 80.w : 60.w,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[600]
                  : Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No chats yet',
              style: GoogleFonts.poppins(
                fontSize: metrics.fontSizeSubtitle,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start a conversation by tapping the chat button',
              style: GoogleFonts.poppins(
                fontSize: metrics.fontSizeSubtitle - 2,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[500]
                    : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutMetrics {
  final bool isTablet;
  final bool isSmallScreen;
  final bool isTallScreen;

  _LayoutMetrics({
    required this.isTablet,
    required this.isSmallScreen,
    required this.isTallScreen,
  });

  double get appBarHeight => isTablet ? 80.h : isTallScreen ? 64.h : 56.h;
  double get fontSizeTitle => isSmallScreen ? 18.sp : isTablet ? 24.sp : 20.sp;
  double get fontSizeSubtitle => isSmallScreen ? 12.sp : isTablet ? 16.sp : 14.sp;
  double get paddingHorizontal => isSmallScreen ? 12.w : isTablet ? 24.w : 16.w;
  double get paddingVertical => isTablet ? 16.h : 12.h;
  double get iconSize => isSmallScreen ? 20.w : isTablet ? 28.w : 24.w;
  double get avatarRadius => isTablet ? 40.r : 30.r;
  double get avatarFontSize => isTablet ? 30.sp : 24.sp;
}
