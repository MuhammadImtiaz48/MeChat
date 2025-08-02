//import 'dart:async';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:imtiaz/firebase_Services/splash_services.dart';
//import 'package:imtiaz/main.dart'; // Ensure Dashbord is correctly imported

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  SplashServices splashServices = SplashServices();
  @override
  void initState(){
    super.initState();
    SplashServices().checkLoginStatus(context);
  }
  // @override
  // void initState() {
  //   super.initState();
  //   // Navigate to Dashboard after 5 seconds
  //   Timer(const Duration(seconds: 5), () {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const Dashboard()),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        decoration: BoxDecoration(
          gradient: LinearGradient(begin:Alignment.bottomRight,end: Alignment.topLeft,  colors: [const Color.fromARGB(255, 251, 253, 150),const Color.fromARGB(255, 245, 157, 157),const Color.fromARGB(255, 251, 253, 150)])
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Subtract.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              "MeChat",
              style: TextStyle(
                color: Color.fromARGB(255, 10, 10, 10),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
