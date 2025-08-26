import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imtiaz/views/auth/login.dart';


class Massage extends StatefulWidget {
  const Massage({super.key});

  @override
  State<Massage> createState() => _MassageState();
}

class _MassageState extends State<Massage> {
  @override
  void initState() {
    super.initState();
    // Navigate to Dashboard after 4 seconds
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Optional: Add your desired background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.message, size: 80, color: Colors.blue), // Optional Icon
            SizedBox(height: 20),
            Text(
              "Account created successfully !",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(), // Loading spinner
          ],
        ),
      ),
    );
  }
}
