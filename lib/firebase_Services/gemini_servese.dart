import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  /// Function for sending only text
  Future<String> sendTextMessage(String prompt) async {
    return await _sendRequest(
      parts: [
        {"text": prompt}
      ],
    );
  }

  /// Function for sending text + image
  Future<String> sendTextWithImage(String prompt, File imageFile) async {
    // Convert image to Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    return await _sendRequest(
      parts: [
        {"text": prompt},
        {
          "inline_data": {
            "mime_type": "image/png", // or image/jpeg
            "data": base64Image,
          }
        }
      ],
    );
  }

  /// Private reusable request function
  Future<String> _sendRequest({required List<Map<String, dynamic>> parts}) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    );

    final body = jsonEncode({
      "contents": [
        {"parts": parts}
      ]
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': apiKey,
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null) {
        final parts = data['candidates'][0]['content']['parts'] as List;

        final aiText = parts
            .map((p) => p['text']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .join("\n");

        return aiText.isNotEmpty ? aiText : "No response from AI";
      } else {
        return "No response from AI";
      }
    } else {
      throw Exception('Failed to fetch response: ${response.body}');
    }
  }
}
