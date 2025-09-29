import 'package:flutter/material.dart';
import 'package:imtiaz/firebase_Services/notification_services.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;

  const IncomingCallScreen({super.key, required this.callerName, required callerId, required callId, required callType});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  @override
  void initState() {
    super.initState();
    RingtoneService.playRingtone();
  }

  @override
  void dispose() {
    RingtoneService.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.callerName,
                style: const TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () {
                    RingtoneService.stopRingtone();
                    // TODO: Navigate to call screen
                  },
                  child: const Icon(Icons.call),
                ),
                const SizedBox(width: 30),
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () {
                    RingtoneService.stopRingtone();
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
