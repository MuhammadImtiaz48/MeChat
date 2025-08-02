import 'package:flutter/material.dart';

class Textfeilds extends StatelessWidget {
  final String text;
  final Icon? icon;
  final bool tohide;
  final TextEditingController? controll;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxlength;
  final  String? hint;

  const Textfeilds({super.key, 
    
    required this.text,
    this.icon,
    this.tohide = false,
    this.controll,
    this.validator,
    this.keyboardType,
    this.maxlength,
    this.hint,

  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      
      controller: controll,
      maxLength: maxlength,
      keyboardType: keyboardType,
      obscureText: tohide,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        labelText: text,
        prefixIcon: icon,
        errorStyle: TextStyle(color: Colors.red),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(11),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 2, 0, 0), width: 2),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
    );
  }
}
