import 'package:flutter/material.dart';

class MessageDetailScreen extends StatelessWidget {
  final String message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Messageiii")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
