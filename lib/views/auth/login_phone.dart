import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:imtiaz/views/auth/otp_screen.dart';
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
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_android, size: 120, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Login with Phone Number",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),

            /// Phone field
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
                fullPhoneNumber = phone.completeNumber;
              },
            ),

            const SizedBox(height: 40),

            /// Verify Button
            SizedBox(
              width: 300,
              child: Buttens(
                bgcolor: Colors.black,
                btname: "Verify",
                textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                callBack: () {
                  if (fullPhoneNumber == null ||
                      fullPhoneNumber!.trim().isEmpty) {
                    Utils().toastMessage("Please enter a valid phone number");
                    return;
                  }

                  auth.verifyPhoneNumber(
                    phoneNumber: fullPhoneNumber!,
                    timeout: const Duration(seconds: 60),

                    /// Auto verification (Android only)
                    verificationCompleted: (PhoneAuthCredential credential) async {
                      try {
                        await auth.signInWithCredential(credential);
                        Utils().toastMessage("Phone number verified automatically!");
                      } catch (e) {
                        Utils().toastMessage("Auto login failed: $e");
                      }
                    },

                    /// If failed
                    verificationFailed: (FirebaseAuthException e) {
                      Utils().toastMessage(e.message ?? "Verification failed");
                    },

                    /// Code sent
                    codeSent: (String verificationId, int? resendToken) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OtpScreen(verificationId: verificationId),
                        ),
                      );
                    },

                    /// Timeout
                    codeAutoRetrievalTimeout: (String verificationId) {
                      Utils().toastMessage("Timeout. Please try again.");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
