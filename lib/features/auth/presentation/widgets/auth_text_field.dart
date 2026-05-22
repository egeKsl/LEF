import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: SecureColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(4.0), // Sharp, tactical corners
        border: Border.all(
          color: SecureColors.surfaceDarkSlate,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: SecureColors.textPrimary,
          fontFamily: 'Inter',
          fontSize: 15.0,
        ),
        cursorColor: SecureColors.cyberBlue,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: SecureColors.textSecondary,
            fontSize: 15.0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}