import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:imtiaz/views/auth/otp_Screen.dart';
import 'package:imtiaz/utils/lnvlidemail.dart'; // Make sure Utils is correctly defined
import 'package:imtiaz/widgets/buttens.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class Loginphone extends StatefulWidget {
  const Loginphone({super.key});

  @override
  State<Loginphone> createState() => _LoginphoneState();
}

class _LoginphoneState extends State<Loginphone> {
  String? fullPhoneNumber;
  final phoneNumberController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.phone_android, size: 150, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Login with phone Number",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            IntlPhoneField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderSide: BorderSide(),
                ),
              ),
              initialCountryCode: 'PK',
              onChanged: (phone) {
                setState(() {
                  fullPhoneNumber = phone.completeNumber;
                });
                print('Complete Phone Number: ${phone.completeNumber}');
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              child: Buttens(
                bgcolor: Colors.black,
                btname: "Verify",
                textStyle: const TextStyle(fontSize: 20, color: Colors.white),
                callBack: () {
                  if (fullPhoneNumber == null) {
                    Utils().toastMessage("Please enter a valid phone number");
                    return;
                  }

                  auth.verifyPhoneNumber(
                    phoneNumber: fullPhoneNumber!,
                    verificationCompleted: (PhoneAuthCredential credential) {
                      // Auto verification (Android only)
                    },
                    verificationFailed: (FirebaseAuthException e) {
                      Utils().toastMessage(e.message ?? "Verification failed");
                    },
                    codeSent: (String verificationId, int? resendToken) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OtpScreen(verificationId: verificationId),
                        ),
                      );
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {
                      Utils().toastMessage("Timeout. Try again.");
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
