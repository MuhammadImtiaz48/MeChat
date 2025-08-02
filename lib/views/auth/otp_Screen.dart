import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:imtiaz/widgets/textfeilds.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  void _verifyOtp() async {
    String otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a 6-digit OTP")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text,
      );

      await _auth.signInWithCredential(credential);

      // Navigate to home screen or dashboard
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP: ${e.message}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // appBar: AppBar(title: Text("Enter OTP",style: TextStyle(fontSize: 25,fontWeight: FontWeight.w500),),centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter OTP ",style: TextStyle(fontSize: 25,fontWeight: FontWeight.w500),),
            SizedBox(height: 20,),
            Icon(Icons.message,size: 100,color: Colors.blue,),
            const Text(
              "Enter the 6-digit code sent to your phone",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Textfeilds(
              maxlength: 6,
              controll: otpController,
              text: "OTP Code",
              keyboardType: TextInputType.numberWithOptions(),
              ),
            // TextField(
            //   controller: otpController,
            //   keyboardType: TextInputType.number,
            //   maxLength: 6,
            //   decoration: InputDecoration(
            //     border: OutlineInputBorder(),
            //     labelText: "OTP Code",
            //   ),
            // ),
             SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Verify OTP",style: TextStyle(color: Colors.white),),
              ),
            )
          ],
        ),
      ),
    );
  }
}
