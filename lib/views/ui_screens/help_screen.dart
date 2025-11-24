import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.w : 16.w;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18.sp : 20.sp,
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
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, isSmallScreen),
            SizedBox(height: 20.h),
            _buildGettingStartedSection(context, isSmallScreen),
            SizedBox(height: 20.h),
            _buildFeaturesSection(context, isSmallScreen),
            SizedBox(height: 20.h),
            _buildTroubleshootingSection(context, isSmallScreen),
            SizedBox(height: 20.h),
            _buildContactSection(context, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.w : 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075E54), Color(0xFF25D366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12.r : 16.r),
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
                Icons.help_outline,
                color: Colors.white,
                size: isSmallScreen ? 24.w : 28.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Welcome to MeChat Help',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18.sp : 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Find answers to your questions and learn how to make the most of MeChat\'s features.',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 13.sp : 14.sp,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
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
            '🚀 Getting Started',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.h : 16.h),
          _buildHelpItem(
            context: context,
            icon: Icons.login,
            title: 'Sign In / Sign Up',
            description: 'Create an account or sign in with your existing credentials to start using MeChat.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.chat_bubble,
            title: 'Start Your First Chat',
            description: 'Tap the green chat button (+) at the bottom right to find and message other users.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.person,
            title: 'Update Your Profile',
            description: 'Go to Settings > Profile to add a profile picture and personalize your account.',
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
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
            '✨ Features Guide',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.h : 16.h),
          _buildHelpItem(
            context: context,
            icon: Icons.chat,
            title: 'Text Messaging',
            description: 'Send and receive text messages in real-time. Messages are delivered instantly.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.attach_file,
            title: 'File & Media Sharing',
            description: 'Share photos, videos, documents, and audio files. Tap the attachment icon to choose files.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.videocam,
            title: 'Voice & Video Calls',
            description: 'Make high-quality voice and video calls. Tap the call/video icons in any chat.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.smart_toy,
            title: 'AI Assistant',
            description: 'Chat with our intelligent AI assistant for help, information, and entertainment.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.done_all,
            title: 'Message Status',
            description: 'See when messages are sent (✓), delivered (✓✓), and read (blue ✓✓).',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Receive notifications for new messages and calls, even when the app is closed.',
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
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
            '🔧 Troubleshooting',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.h : 16.h),
          _buildHelpItem(
            context: context,
            icon: Icons.wifi_off,
            title: 'No Internet Connection',
            description: 'Check your internet connection. MeChat works offline for cached messages but needs internet for sending.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.notifications_off,
            title: 'Not Receiving Notifications',
            description: 'Check notification permissions in your device settings and ensure MeChat notifications are enabled.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.call_end,
            title: 'Call Issues',
            description: 'Ensure you have a stable internet connection and microphone/camera permissions for calls.',
            isSmallScreen: isSmallScreen,
          ),
          _buildHelpItem(
            context: context,
            icon: Icons.refresh,
            title: 'App Not Responding',
            description: 'Try restarting the app or clearing cache. If issues persist, contact support.',
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
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
            '📞 Contact Support',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.h : 16.h),
          Text(
            'Need more help? Contact us directly!',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 13.sp : 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10.w : 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email,
                  color: const Color(0xFF075E54),
                  size: isSmallScreen ? 20.w : 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Support',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'cose101048@gmail.com',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12.sp : 13.sp,
                          color: const Color(0xFF075E54),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: 'cose101048@gmail.com'));
                    Get.snackbar(
                      'Email Copied',
                      'cose101048@gmail.com copied to clipboard',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: Icon(
                    Icons.copy,
                    color: const Color(0xFF075E54),
                    size: isSmallScreen ? 18.w : 20.w,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10.w : 12.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.call,
                  color: Colors.green,
                  size: isSmallScreen ? 20.w : 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Support',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '+92 341 0333820',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12.sp : 13.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: '923410333820'));
                    Get.snackbar(
                      'Phone Copied',
                      '+92 341 0333820 copied to clipboard',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: Icon(
                    Icons.copy,
                    color: Colors.green,
                    size: isSmallScreen ? 18.w : 20.w,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.h : 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Create email URI with proper encoding
                    final String emailSubject = Uri.encodeComponent('MeChat Support Request');
                    final String emailBody = Uri.encodeComponent('Hello,\n\nI need help with MeChat app.\n\n[Please describe your issue here]\n\nBest regards,\n[Your Name]');
                    final String mailtoUrl = 'mailto:cose101048@gmail.com?subject=$emailSubject&body=$emailBody';

                    try {
                      final Uri emailUri = Uri.parse(mailtoUrl);
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                        Get.snackbar(
                          'Email Opened',
                          'Email app opened with support details',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      } else {
                        // If mailto fails, try to open Gmail specifically
                        try {
                          final String gmailUrl = 'googlegmail://co?to=cose101048@gmail.com&subject=$emailSubject&body=$emailBody';
                          final Uri gmailUri = Uri.parse(gmailUrl);
                          if (await canLaunchUrl(gmailUri)) {
                            await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
                            Get.snackbar(
                              'Gmail Opened',
                              'Gmail opened with support details',
                              backgroundColor: Colors.blue,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            throw 'Gmail not available';
                          }
                        } catch (e) {
                          // Final fallback - copy to clipboard
                          await Clipboard.setData(const ClipboardData(text: 'cose101048@gmail.com'));
                          Get.snackbar(
                            'Email Copied',
                            'cose101048@gmail.com copied to clipboard',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        }
                      }
                    } catch (e) {
                      await Clipboard.setData(const ClipboardData(text: 'cose101048@gmail.com'));
                      Get.snackbar(
                        'Error',
                        'Email copied to clipboard: cose101048@gmail.com',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                  icon: Icon(Icons.email, size: isSmallScreen ? 16.w : 18.w),
                  label: Text(
                    'Email Support',
                    style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13.sp : 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: '923410333820',
                    );

                    try {
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        await Clipboard.setData(const ClipboardData(text: '923410333820'));
                        Get.snackbar(
                          'Phone Dialer Not Available',
                          'Phone number copied to clipboard: 923410333820',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    } catch (e) {
                      await Clipboard.setData(const ClipboardData(text: '923410333820'));
                      Get.snackbar(
                        'Error',
                        'Phone number copied to clipboard: 923410333820',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                  icon: Icon(Icons.call, size: isSmallScreen ? 16.w : 18.w),
                  label: Text(
                    'Call Support',
                    style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13.sp : 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10.h : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6.w : 8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 6.r : 8.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF075E54),
              size: isSmallScreen ? 18.w : 20.w,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10.w : 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 13.sp : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11.sp : 12.sp,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}