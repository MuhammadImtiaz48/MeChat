import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../firebase_Services/gemini_servese.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  File? _selectedImage;
  bool _isLoading = false;
  late final GeminiService _geminiService;

  final String apiKey = "AIzaSyAgt_PyIoeKrOIiWXcMKme-hk_jhxOTOP0"; // Gemini API key

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(apiKey: apiKey);
  }

  // Pick image from gallery/camera
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Send message (with optional image) to Gemini
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": _controller.text,
        "image": _selectedImage,
      });
      _isLoading = true;
    });

    try {
      String reply;
      if (_selectedImage != null) {
        reply = await _geminiService.sendTextWithImage(_controller.text, _selectedImage!);
      } else {
        reply = await _geminiService.sendTextMessage(_controller.text);
      }

      setState(() {
        _messages.add({"sender": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "ai",
          "text": "Error: $e"
        });
      });
    }

    setState(() {
      _isLoading = false;
      _controller.clear();
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "MeChat AI",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFECE5DD),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["sender"] == "user";
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (msg["text"] != null && msg["text"].toString().isNotEmpty)
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF075E54)
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: Theme.of(context).brightness == Brightness.dark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: isUser
                                ? Text(
                                    msg["text"],
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  )
                                : SelectableText(
                                    msg["text"],
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        if (msg["image"] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                msg["image"],
                                width: 150,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF075E54)),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF075E54)),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        hintStyle: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF075E54)),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF075E54)),
                          onPressed: _sendMessage,
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