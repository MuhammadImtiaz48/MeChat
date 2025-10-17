import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:imtiaz/models/massagesmodel.dart';

// MessageType enum is now imported from massagesmodel.dart

class ChatMessageCard extends StatelessWidget {
  final String currentUserId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime time;
  final bool seen;
  final bool showSeen;
  final double maxWidth;
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;

  const ChatMessageCard({
    super.key,
    required this.currentUserId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.time,
    required this.seen,
    required this.showSeen,
    required this.maxWidth,
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
  });

  Widget _buildMessageContent() {
    switch (type) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.file:
        return _buildFileMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      message,
      style: TextStyle(
        fontSize: 16.sp,
        color: Colors.black87,
        fontFamily: 'Poppins',
        height: 1.2,
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.isNotEmpty) ...[
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
        ],
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth * 0.8, maxHeight: 200.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: mediaUrl != null
                ? Image.network(
                    mediaUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[600]),
                      );
                    },
                  )
                : Container(
                    width: 100.w,
                    height: 100.h,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey[600]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.isNotEmpty) ...[
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
        ],
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth * 0.8, maxHeight: 200.h),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (mediaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    mediaUrl!,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.7),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.video_file, color: Colors.white, size: 40.w),
                      );
                    },
                  ),
                ),
              Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 50.w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessage() {
    return Row(
      children: [
        Icon(
          Icons.play_circle_fill,
          color: const Color(0xFF075E54),
          size: 40.w,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName ?? 'Voice message',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (fileSize != null)
                Text(
                  '${(fileSize! / 1024).round()} KB',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage() {
    return Row(
      children: [
        Icon(
          _getFileIcon(fileName ?? ''),
          color: const Color(0xFF075E54),
          size: 40.w,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName ?? 'File',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (fileSize != null)
                Text(
                  _formatFileSize(fileSize!),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = senderId == currentUserId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;

    // Responsive dimensions
    final marginHorizontal = isSmallScreen ? 6.w : isTablet ? 12.w : 8.w;
    final paddingHorizontal = isSmallScreen ? 8.w : isTablet ? 16.w : 12.w;
    final paddingVertical = isSmallScreen ? 6.h : isTablet ? 12.h : 8.h;
    final fontSizeTime = isSmallScreen ? 10.sp : isTablet ? 13.sp : 12.sp;
    final iconSize = isSmallScreen ? 14.w : isTablet ? 18.w : 16.w;
    final borderRadius = isSmallScreen ? 10.r : isTablet ? 14.r : 12.r;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? marginHorizontal * 8 : marginHorizontal,
            right: isMe ? marginHorizontal : marginHorizontal * 8,
            top: marginHorizontal * 0.5,
            bottom: marginHorizontal * 0.5,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? borderRadius : 0),
              topRight: Radius.circular(isMe ? 0 : borderRadius),
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildMessageContent(),
              SizedBox(height: isTablet ? 6.h : 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(time),
                    style: TextStyle(
                      fontSize: fontSizeTime,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (isMe && showSeen) ...[
                    SizedBox(width: isTablet ? 6.w : 4.w),
                    Icon(
                      seen ? Icons.done_all : Icons.done,
                      size: iconSize,
                      color: seen ? const Color(0xFF34B7F1) : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}