import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/controllers/chat_controller.dart';
import 'package:imtiaz/firebase_Services/cloudinary_service.dart';
import 'package:imtiaz/firebase_Services/notification_services.dart';
import 'package:imtiaz/models/massagesmodel.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/views/ui_screens/user_profile.dart';
import 'package:imtiaz/widgets/chatmaasgeCard.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final UserchatModel user;
  final String loggedInUserName;

  const ChatScreen({
    super.key,
    required this.user,
    required this.loggedInUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController msgController;
  late final ScrollController scrollController;
  late final FocusNode focusNode;
  late final ChatController controller;
  late final AppController appController;
  late final CloudinaryService cloudinaryService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isCalling = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('ChatScreen: Initializing for user ${widget.user.uid} at ${DateTime.now()}');
    }
    Get.put(ChatController(user: widget.user, loggedInUserName: widget.loggedInUserName), tag: widget.user.uid);
    NotificationService.setCurrentChatId(widget.user.uid);
    controller = Get.find<ChatController>(tag: widget.user.uid); // Moved before NotificationService.init
    NotificationService.init(onNotificationTap: (payload) async {
      if (payload['type'] == 'call' && payload['chatId'] == widget.user.uid) {
        final callType = payload['callType'] ?? 'voice';
        final callId = payload['callId'] ?? controller.chatRoomId; // Fallback to chatRoomId
        if (kDebugMode) {
          debugPrint('ChatScreen: Handling call notification tap: $payload');
        }
        Get.to(() => ZegoUIKitPrebuiltCall(
              appID: 116174848,
              appSign: '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679',
              userID: FirebaseAuth.instance.currentUser!.uid,
              userName: widget.loggedInUserName.isNotEmpty ? widget.loggedInUserName : 'User',
              callID: callId, // Use non-null callId
              config: callType == 'video'
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
            ));
      } else if (payload['type'] == 'message') {
        Get.toNamed('/chat', arguments: {
          'user': widget.user,
          'loggedInUserName': widget.loggedInUserName,
        });
      }
    });
    msgController = TextEditingController();
    scrollController = ScrollController();
    focusNode = FocusNode();
    appController = Get.find<AppController>();
    cloudinaryService = CloudinaryService();
    _initializeConnectivity();
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }


  Future<void> _initializeConnectivity() async {
    try {
      if (kDebugMode) {
        debugPrint('ChatScreen: Checking connectivity');
      }
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 5));
      controller.isOnline.value = !connectivityResult.contains(ConnectivityResult.none);
      if (!controller.isOnline.value && mounted) {
        _showSnackBar('Offline', 'Showing cached messages. Sending disabled.', Colors.orange);
      }
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final isOnline = !results.contains(ConnectivityResult.none);
        controller.isOnline.value = isOnline;
        if (!isOnline && mounted) {
          _showSnackBar('Offline', 'Showing cached messages. Sending disabled.', Colors.orange);
        } else {
          controller.listenToLastSeen();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatScreen: Connectivity error: $e');
      }
      controller.isOnline.value = false;
      if (mounted) {
        _showSnackBar('Error', 'Unable to check network connection', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('ChatScreen: Disposing for user ${widget.user.uid} at ${DateTime.now()}');
    }
    NotificationService.setCurrentChatId(null);
    _connectivitySubscription?.cancel();
    msgController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    Get.delete<ChatController>(tag: widget.user.uid);
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
              'Share',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.green,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () => _pickVideo(),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () => _pickDocument(),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.black87,
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
        await _uploadAndSendMedia(File(pickedFile.path), MessageType.image);
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to pick image: $e', Colors.red);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        await _uploadAndSendMedia(File(pickedFile.path), MessageType.video);
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to pick video: $e', Colors.red);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _uploadAndSendMedia(file, MessageType.file, fileName: result.files.single.name, message: msgController.text.trim());
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to pick document: $e', Colors.red);
    }
  }

  Future<void> _uploadAndSendMedia(File file, MessageType type, {String? fileName, String? message}) async {
    if (!controller.isOnline.value) {
      _showSnackBar('Offline', 'Cannot send media while offline', Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? mediaUrl;
      String? finalFileName = fileName;

      switch (type) {
        case MessageType.image:
          mediaUrl = await cloudinaryService.uploadImageToCloudinary(file);
          break;
        case MessageType.video:
          mediaUrl = await cloudinaryService.uploadVideoToCloudinary(file);
          break;
        case MessageType.file:
          mediaUrl = await cloudinaryService.uploadFileToCloudinary(file);
          break;
        default:
          break;
      }

      if (mediaUrl != null) {
        final messageText = message ?? msgController.text.trim();
        final messageModel = MessageModel(
          senderId: FirebaseAuth.instance.currentUser!.uid,
          text: messageText,
          timestamp: DateTime.now(),
          type: type,
          mediaUrl: mediaUrl,
          fileName: finalFileName,
          fileSize: await file.length(),
        );

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(controller.chatRoomId)
            .collection('messages')
            .add(messageModel.toMap());

        msgController.clear();
        _scrollToBottom();
        _showSnackBar('Success', '${type.toString().split('.').last} sent!', Colors.green);
      } else {
        _showSnackBar('Error', 'Failed to upload ${type.toString().split('.').last}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to send media: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 780),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isTablet = screenWidth >= 600;
        final isSmallScreen = screenWidth < 360;
        final isTallScreen = screenHeight > 750;

        final appBarHeight = isTablet ? 80.h : isTallScreen ? 64.h : 56.h;
        final avatarRadius = isSmallScreen ? 20.r : isTablet ? 28.r : 24.r;
        final fontSizeTitle = isSmallScreen ? 14.sp : isTablet ? 18.sp : 16.sp;
        final fontSizeSubtitle = isSmallScreen ? 10.sp : isTablet ? 13.sp : 11.sp;
        final fontSizeTyping = isTablet ? 15.sp : isTallScreen ? 14.sp : 13.sp;
        final iconSize = isSmallScreen ? 20.w : isTablet ? 24.w : 22.w;
        final paddingHorizontal = isSmallScreen ? 8.w : screenWidth * 0.02;
        final paddingVertical = isTallScreen ? 8.h : 6.h;

        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(appBarHeight),
            child: AppBar(
              backgroundColor: const Color(0xFF075E54),
              elevation: 0,
              toolbarHeight: appBarHeight,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF075E54),
                ),
              ),
              leadingWidth: isSmallScreen ? 80.w : isTablet ? 100.w : 90.w,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: paddingHorizontal * 0.5, right: paddingHorizontal * 0.2),
                    child: IconButton(
                      constraints: BoxConstraints(maxWidth: isSmallScreen ? 20.w : 24.w),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize * 0.8),
                      onPressed: () => Get.back(),
                      tooltip: 'Back',
                    ),
                  ),
                  Flexible(
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey[400],
                      backgroundImage: widget.user.profilePic.isNotEmpty ? NetworkImage(widget.user.profilePic) : null,
                      child: widget.user.profilePic.isEmpty
                          ? Text(
                              widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: avatarRadius * 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              title: GestureDetector(
                onTap: () async {
                  for (int i = 0; i < 3; i++) {
                    try {
                      if (kDebugMode) {
                        debugPrint('ChatScreen: Loading profile for ${widget.user.uid}');
                      }
                      UserchatModel userProfile = widget.user;
                      if (controller.isOnline.value) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid)
                            .get()
                            .timeout(const Duration(seconds: 10));
                        if (userDoc.exists) {
                          userProfile = UserchatModel.fromMap(userDoc.data()!);
                        }
                      }
                      Get.to(() => UserProfileScreen(user: userProfile, userId: userProfile.uid, userName: userProfile.name));
                      return;
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ ChatScreen: Error loading profile (attempt ${i + 1}): $e');
                      }
                      if (i == 2) {
                        _showSnackBar(
                          'Error',
                          'Failed to load profile: ${controller.isOnline.value ? 'Network error' : 'Offline mode'}',
                          Colors.red,
                        );
                      }
                      await Future.delayed(const Duration(seconds: 2));
                    }
                  }
                },
                child: Container(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty ? widget.user.name : 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: isTablet ? 3.h : 2.h),
                      Obx(() => Text(
                            controller.lastSeen.value.isNotEmpty
                                ? controller.lastSeen.value
                                : controller.isOnline.value ? 'Checking status...' : 'Offline',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeSubtitle,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )),
                    ],
                  ),
                ),
              ),
              actions: [
                Obx(() => IconButton(
                      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal * 0.5),
                      constraints: BoxConstraints(maxWidth: isSmallScreen ? 30.w : isTablet ? 40.w : 36.w),
                      icon: _isCalling
                          ? SizedBox(
                              width: iconSize * 0.6,
                              height: iconSize * 0.6,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.videocam, color: Colors.white, size: iconSize),
                      onPressed: controller.isOnline.value && appController.isZegoInitialized.value && !_isCalling
                          ? () async {
                              setState(() {
                                _isCalling = true;
                              });
                              try {
                                await controller.startCall(isVideo: true);
                                _showSnackBar('Success', 'Video call initiated', Colors.green);
                              } catch (e) {
                                _showSnackBar('Error', 'Video call failed: Network issue', Colors.red);
                              } finally {
                                setState(() {
                                  _isCalling = false;
                                });
                              }
                            }
                          : () => _showSnackBar(
                                'Error',
                                controller.isOnline.value ? 'Call service unavailable' : 'Offline mode',
                                Colors.red,
                              ),
                      tooltip: 'Video Call',
                    )),
                Obx(() => IconButton(
                      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal * 0.5),
                      constraints: BoxConstraints(maxWidth: isSmallScreen ? 30.w : isTablet ? 40.w : 36.w),
                      icon: _isCalling
                          ? SizedBox(
                              width: iconSize * 0.6,
                              height: iconSize * 0.6,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.call, color: Colors.white, size: iconSize),
                      onPressed: controller.isOnline.value && appController.isZegoInitialized.value && !_isCalling
                          ? () async {
                              setState(() {
                                _isCalling = true;
                              });
                              try {
                                await controller.startCall(isVideo: false);
                                _showSnackBar('Success', 'Voice call initiated', Colors.green);
                              } catch (e) {
                                _showSnackBar('Error', 'Voice call failed: Network issue', Colors.red);
                              } finally {
                                setState(() {
                                  _isCalling = false;
                                });
                              }
                            }
                          : () => _showSnackBar(
                                'Error',
                                controller.isOnline.value ? 'Call service unavailable' : 'Offline mode',
                                Colors.red,
                              ),
                      tooltip: 'Voice Call',
                    )),
                PopupMenuButton<String>(
                  padding: EdgeInsets.only(right: paddingHorizontal * 0.5),
                  icon: Icon(Icons.more_vert, color: Colors.white, size: iconSize * 0.9),
                  offset: Offset(0, appBarHeight * 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Text('View Contact', style: GoogleFonts.poppins(fontSize: fontSizeSubtitle)),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Text('Clear Chat', style: GoogleFonts.poppins(fontSize: fontSizeSubtitle)),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'profile') {
                      for (int i = 0; i < 3; i++) {
                        try {
                          if (kDebugMode) {
                            debugPrint('ChatScreen: Loading profile for ${widget.user.uid}');
                          }
                          UserchatModel userProfile = widget.user;
                          if (controller.isOnline.value) {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.user.uid)
                                .get()
                                .timeout(const Duration(seconds: 10));
                            if (userDoc.exists) {
                              userProfile = UserchatModel.fromMap(userDoc.data()!);
                            }
                          }
                          Get.to(() => UserProfileScreen(user: userProfile, userId: userProfile.uid, userName: userProfile.name));
                          return;
                        } catch (e) {
                          if (kDebugMode) {
                            debugPrint('❌ ChatScreen: Error loading profile (attempt ${i + 1}): $e');
                          }
                          if (i == 2) {
                            _showSnackBar(
                              'Error',
                              'Failed to load profile: ${controller.isOnline.value ? 'Network error' : 'Offline mode'}',
                              Colors.red,
                            );
                          }
                          await Future.delayed(const Duration(seconds: 2));
                        }
                      }
                    } else if (value == 'clear') {
                      Get.dialog(
                        AlertDialog(
                          title: Text('Clear Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to clear this chat?', style: GoogleFonts.poppins()),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF075E54))),
                            ),
                            TextButton(
                              onPressed: () async {
                                for (int i = 0; i < 3; i++) {
                                  try {
                                    if (kDebugMode) {
                                      debugPrint('ChatScreen: Clearing chat for ${controller.chatRoomId}');
                                    }
                                    if (controller.isOnline.value) {
                                      final snapshot = await FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(controller.chatRoomId)
                                          .collection('messages')
                                          .get()
                                          .timeout(const Duration(seconds: 10));
                                      final batch = FirebaseFirestore.instance.batch();
                                      for (var doc in snapshot.docs) {
                                        batch.delete(doc.reference);
                                      }
                                      await batch.commit().timeout(const Duration(seconds: 10));
                                    }
                                    controller.cachedMessages.clear();
                                    await controller.cacheMessages([]);
                                    Get.back();
                                    _showSnackBar('Success', 'Chat cleared', Colors.green);
                                    _scrollToBottom();
                                    return;
                                  } catch (e) {
                                    if (kDebugMode) {
                                      debugPrint('❌ ChatScreen: Error clearing chat (attempt ${i + 1}): $e');
                                    }
                                    if (i == 2) {
                                      _showSnackBar('Error', 'Failed to clear chat: Network error', Colors.red);
                                    }
                                    await Future.delayed(const Duration(seconds: 2));
                                  }
                                }
                              },
                              child: Text('Clear', style: GoogleFonts.poppins(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFECE5DD),
            ),
            child: Column(
              children: [
                Obx(() {
                  if (!controller.isOnline.value) {
                    return Container(
                      color: Colors.orange[100],
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Center(
                        child: Text(
                          'Offline: Showing cached messages',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Expanded(
                  child: Obx(() => StreamBuilder<QuerySnapshot>(
                        stream: controller.isOnline.value
                            ? FirebaseFirestore.instance
                                .collection('chats')
                                .doc(controller.chatRoomId)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(30)
                                .snapshots()
                            : null,
                        builder: (context, snapshot) {
                          if (!controller.isOnline.value) {
                            return ListView.builder(
                              controller: scrollController,
                              reverse: true,
                              padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
                              itemCount: controller.cachedMessages.length,
                              itemBuilder: (context, index) {
                                final msg = controller.cachedMessages[index];
                                final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                                DateTime time;
                                try {
                                  time = msg['timestamp'] is Timestamp
                                      ? (msg['timestamp'] as Timestamp).toDate()
                                      : (msg['timestamp'] is String
                                          ? DateTime.parse(msg['timestamp'])
                                          : DateTime.now());
                                } catch (e) {
                                  time = DateTime.now();
                                  if (kDebugMode) {
                                    debugPrint('❌ ChatScreen: Error parsing timestamp: $e');
                                  }
                                }
                                return ChatMessageCard(
                                  currentUserId: FirebaseAuth.instance.currentUser!.uid,
                                  senderId: msg['senderId'],
                                  senderName: isMe ? controller.myName.value : widget.user.name,
                                  message: msg['text'] ?? msg['message'] ?? '',
                                  time: time,
                                  seen: msg['seen'] ?? false,
                                  showSeen: isMe,
                                  maxWidth: screenWidth * 0.75,
                                  type: MessageType.values.firstWhere(
                                    (e) => e.toString() == 'MessageType.${msg['type'] ?? 'text'}',
                                    orElse: () => MessageType.text,
                                  ),
                                  mediaUrl: msg['mediaUrl'],
                                  fileName: msg['fileName'],
                                  fileSize: msg['fileSize'],
                                );
                              },
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF075E54)));
                          }
                          if (snapshot.hasError) {
                            if (kDebugMode) {
                              debugPrint('❌ ChatScreen: Stream error: ${snapshot.error}');
                            }
                            return Center(
                              child: Text(
                                'Error loading messages',
                                style: GoogleFonts.poppins(fontSize: isTablet ? 16.sp : 14.sp, color: Colors.red),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    controller.isOnline.value ? Icons.chat : Icons.cloud_off,
                                    size: isTablet ? 70.w : 50.w,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 15.h),
                                  Text(
                                    controller.isOnline.value ? 'Start a conversation' : 'Offline: No cached messages',
                                    style: GoogleFonts.poppins(fontSize: isTablet ? 16.sp : 14.sp, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final messages = snapshot.data!.docs;
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            controller.markMessagesSeen();
                            _scrollToBottom();
                          });

                          return ListView.builder(
                            controller: scrollController,
                            reverse: true,
                            padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index].data() as Map<String, dynamic>;
                              final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                              return ChatMessageCard(
                                currentUserId: FirebaseAuth.instance.currentUser!.uid,
                                senderId: msg['senderId'],
                                senderName: isMe ? controller.myName.value : widget.user.name,
                                message: msg['text'] ?? '',
                                time: (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                seen: msg['seen'] ?? false,
                                showSeen: isMe,
                                maxWidth: screenWidth * 0.75,
                                type: MessageType.values.firstWhere(
                                  (e) => e.toString() == 'MessageType.${msg['type'] ?? 'text'}',
                                  orElse: () => MessageType.text,
                                ),
                                mediaUrl: msg['mediaUrl'],
                                fileName: msg['fileName'],
                                fileSize: msg['fileSize'],
                              );
                            },
                          );
                        },
                      )),
                ),
                Obx(() => StreamBuilder<DocumentSnapshot>(
                      stream: controller.isOnline.value
                          ? FirebaseFirestore.instance.collection('chats').doc(controller.chatRoomId).snapshots()
                          : null,
                      builder: (context, snapshot) {
                        if (controller.isOnline.value && snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final isTyping = data?['typing_${widget.user.uid}'] as bool? ?? false;
                          if (isTyping) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal + 6.w, vertical: paddingVertical),
                              color: const Color(0xFFECE5DD),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Typing...',
                                    style: GoogleFonts.poppins(
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF25D366),
                                      fontSize: fontSizeTyping,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    )),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
                  color: const Color(0xFFECE5DD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: const Color(0xFF075E54),
                          size: isTablet ? 24.w : 20.w,
                        ),
                        onPressed: _showAttachmentOptions,
                        tooltip: 'Attach',
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25.r),
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: isTallScreen ? 100.h : 80.h),
                            child: TextField(
                              controller: msgController,
                              focusNode: focusNode,
                              enabled: controller.isOnline.value,
                              decoration: InputDecoration(
                                hintText: controller.isOnline.value ? 'Type a message' : 'Offline: Cannot send messages',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: isTablet ? 15.sp : 13.sp),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: paddingHorizontal + 10.w, vertical: paddingVertical + 6.h),
                              ),
                              style: GoogleFonts.poppins(fontSize: isTablet ? 15.sp : 13.sp),
                              minLines: 1,
                              maxLines: 4,
                              onChanged: (text) => controller.isOnline.value ? controller.handleTypingStatus(text, focusNode.hasFocus) : null,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: paddingHorizontal),
                      CircleAvatar(
                        radius: isSmallScreen ? 22.r : isTablet ? 26.r : 24.r,
                        backgroundColor: _isUploading || controller.isSending.value || !controller.isOnline.value
                            ? Colors.grey[400]
                            : const Color(0xFF25D366),
                        child: _isUploading
                            ? SizedBox(
                                width: isTablet ? 16.w : 14.w,
                                height: isTablet ? 16.w : 14.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  color: Colors.white,
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send, color: Colors.white, size: isTablet ? 16.w : 14.w),
                                onPressed: controller.isSending.value || !controller.isOnline.value || _isUploading
                                    ? null
                                    : () {
                                        if (msgController.text.trim().isNotEmpty) {
                                          controller.sendMessage(msgController.text);
                                          msgController.clear();
                                          _scrollToBottom();
                                        }
                                      },
                                tooltip: 'Send',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}