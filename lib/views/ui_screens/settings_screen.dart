import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imtiaz/firebase_Services/cloudinary_service.dart';
import 'package:imtiaz/views/ui_screens/help_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  File? _selectedImage;
  bool _isUploading = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'English';
  bool _lastSeenVisible = true;
  bool _profilePicVisible = true;
  bool _statusVisible = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _lastSeenVisible = prefs.getBool('last_seen_visible') ?? true;
      _profilePicVisible = prefs.getBool('profile_pic_visible') ?? true;
      _statusVisible = prefs.getBool('status_visible') ?? true;
    });
    // Update locale
    _updateLocale(_selectedLanguage);
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _updateLocale(String language) {
    Locale locale;
    if (language == 'English') {
      locale = const Locale('en', 'US');
    } else if (language == 'العربية') {
      locale = const Locale('ar', 'SA');
    } else if (language == 'Español') {
      locale = const Locale('es', 'ES');
    } else if (language == 'Français') {
      locale = const Locale('fr', 'FR');
    } else if (language == 'Deutsch') {
      locale = const Locale('de', 'DE');
    } else {
      locale = const Locale('en', 'US');
    }
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            SizedBox(height: 24.h),
            _buildThemeSection(),
            SizedBox(height: 24.h),
            _buildNotificationsSection(),
            SizedBox(height: 24.h),
            _buildPrivacySection(),
            SizedBox(height: 24.h),
            _buildStorageSection(),
            SizedBox(height: 24.h),
            _buildAccountSection(),
            SizedBox(height: 24.h),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_auth.currentUser?.photoURL != null
                          ? NetworkImage(_auth.currentUser!.photoURL!)
                          : null),
                  child: _selectedImage == null && _auth.currentUser?.photoURL == null
                      ? Text(
                          _auth.currentUser?.displayName?.isNotEmpty == true
                              ? _auth.currentUser!.displayName![0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Tap the camera icon to change your profile picture',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          if (_isUploading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF25D366))),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF075E54),
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        Theme.of(context).brightness == Brightness.dark ? 'Dark Mode' : 'Light Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: const Color(0xFF25D366),
                  activeTrackColor: const Color(0xFF25D366).withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF075E54),
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive notifications for new messages',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('sound_enabled', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSetting('vibration_enabled', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Security',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildListTile(
            icon: Icons.lock,
            title: 'Privacy Settings',
            subtitle: 'Manage who can see your info',
            onTap: () => _showPrivacyDialog(),
          ),
          _buildListTile(
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage blocked contacts',
            onTap: () => _showBlockedUsersScreen(),
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            subtitle: 'Add extra security to your account',
            onTap: () => _showTwoFADialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage & Data',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildListTile(
            icon: Icons.storage,
            title: 'Storage Usage',
            subtitle: 'Manage your storage space',
            onTap: () => _showStorageScreen(),
          ),
          _buildListTile(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Backup your chats and data',
            onTap: () => _showBackupDialog(),
          ),
          _buildListTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _clearCache(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildListTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: () => _showLanguageDialog(),
          ),
          _buildListTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => Get.to(() => const HelpScreen()),
          ),
          _buildListTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showSignOutDialog(),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075E54), Color(0xFF25D366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'About MeChat',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Welcome to MeChat - Your Ultimate Communication Companion! 🌟\n\n'
            'MeChat is a modern, feature-rich messaging application designed to connect people seamlessly. '
            'With real-time messaging, high-quality voice and video calls, AI-powered assistance, and a beautiful interface, '
            'MeChat brings the future of communication to your fingertips.\n\n'
            '✨ Key Features:\n'
            '• Instant messaging with read receipts\n'
            '• High-quality voice and video calling\n'
            '• AI assistant for smart conversations\n'
            '• File and media sharing\n'
            '• Dark/Light theme support\n'
            '• Secure and private communication\n'
            '• Cross-platform compatibility\n\n'
            'Experience the next generation of messaging with MeChat. '
            'Stay connected, stay informed, and stay ahead with our innovative features!\n\n'
            'Made with ❤️ for better communication.',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF075E54),
          size: 24.w,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF25D366),
          activeTrackColor: const Color(0xFF25D366).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF075E54),
          size: 24.w,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: textColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16.w,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('العربية'),
            _buildLanguageOption('Español'),
            _buildLanguageOption('Français'),
            _buildLanguageOption('Deutsch'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language, style: GoogleFonts.poppins()),
      leading: Radio<String>(
        value: language,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          setState(() => _selectedLanguage = value!);
          _saveSetting('language', value!);
          _updateLocale(value!);
          Get.back();
          Get.snackbar('Language', 'Language changed to $value', backgroundColor: Colors.green, colorText: Colors.white);
        },
        activeColor: const Color(0xFF25D366),
      ),
      onTap: () {
        setState(() => _selectedLanguage = language);
        _saveSetting('language', language);
        _updateLocale(language);
        Get.back();
        Get.snackbar('Language', 'Language changed to $language', backgroundColor: Colors.green, colorText: Colors.white);
      },
    );
  }

  void _showSignOutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _auth.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Get.offAllNamed('/login');
            },
            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Privacy Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSwitchTileDialog(
                title: 'Last Seen',
                subtitle: 'Show when you were last active',
                value: _lastSeenVisible,
                onChanged: (value) {
                  setState(() => _lastSeenVisible = value);
                  _saveSetting('last_seen_visible', value);
                },
              ),
              _buildSwitchTileDialog(
                title: 'Profile Picture',
                subtitle: 'Show your profile picture',
                value: _profilePicVisible,
                onChanged: (value) {
                  setState(() => _profilePicVisible = value);
                  _saveSetting('profile_pic_visible', value);
                },
              ),
              _buildSwitchTileDialog(
                title: 'Status',
                subtitle: 'Show your status',
                value: _statusVisible,
                onChanged: (value) {
                  setState(() => _statusVisible = value);
                  _saveSetting('status_visible', value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
        ],
      ),
    );
  }

  void _showTwoFADialog() {
    bool is2FAEnabled = false; // For demo, assume not enabled
    Get.dialog(
      AlertDialog(
        title: Text('Two-Factor Authentication', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add an extra layer of security to your account.', style: GoogleFonts.poppins()),
              SizedBox(height: 16.h),
              _buildSwitchTileDialog(
                title: 'Enable 2FA',
                subtitle: 'Use SMS or authenticator app',
                value: is2FAEnabled,
                onChanged: (value) {
                  setState(() => is2FAEnabled = value);
                  // Here you would implement actual 2FA setup
                  Get.snackbar('2FA', value ? '2FA Enabled' : '2FA Disabled', backgroundColor: Colors.green, colorText: Colors.white);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
        ],
      ),
    );
  }

  void _showStorageScreen() {
    Get.to(() => Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Text('Storage Usage', style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage Breakdown', style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            SizedBox(height: 16.h),
            _buildStorageItem('Chats', '2.5 MB', 0.25),
            _buildStorageItem('Media', '15.3 MB', 0.45),
            _buildStorageItem('Documents', '1.2 MB', 0.1),
            _buildStorageItem('Others', '0.8 MB', 0.2),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Text('Total Used: 19.8 MB', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  Text('Available: 4.2 GB', style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Backup & Restore', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Backup your chats and data to keep them safe.', style: GoogleFonts.poppins()),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.snackbar('Backup', 'Backup created successfully!', backgroundColor: Colors.green, colorText: Colors.white);
              },
              icon: const Icon(Icons.backup, color: Colors.white),
              label: Text('Create Backup', style: GoogleFonts.poppins(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                minimumSize: Size(double.infinity, 48.h),
              ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () {
                Get.back();
                Get.snackbar('Restore', 'Data restored successfully!', backgroundColor: Colors.blue, colorText: Colors.white);
              },
              icon: const Icon(Icons.restore, color: Color(0xFF075E54)),
              label: Text('Restore from Backup', style: GoogleFonts.poppins(color: Color(0xFF075E54))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF075E54)),
                minimumSize: Size(double.infinity, 48.h),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    Get.dialog(
      AlertDialog(
        title: Text('Clear Cache', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This will clear temporary files and free up storage space. Continue?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Simulate clearing cache
              Get.snackbar('Cache Cleared', 'Cache cleared successfully!', backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: Text('Clear', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String title, String size, double percentage) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                Text(size, style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(
            width: 80.w,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF25D366)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersScreen() {
    Get.to(() => Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Text('Blocked Users', style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text('No blocked users', style: GoogleFonts.poppins(fontSize: 18.sp, color: Colors.grey[600])),
            SizedBox(height: 8.h),
            Text('Users you block will appear here', style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[500])),
          ],
        ),
      ),
    ));
  }

  Widget _buildSwitchTileDialog({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF25D366),
            activeTrackColor: const Color(0xFF25D366).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Profile Picture',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF075E54),
              size: 24.w,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadProfilePicture();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImageToCloudinary(_selectedImage!);

      if (imageUrl != null) {
        // Update Firebase Auth user profile
        await _auth.currentUser?.updatePhotoURL(imageUrl);

        // Update Firestore user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'profilePic': imageUrl});

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profilePic', imageUrl);

        Get.snackbar(
          'Success',
          'Profile picture updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload profile picture: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }
}