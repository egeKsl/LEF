import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class CustomServerTextField extends StatelessWidget {
  final TextEditingController controller;

  const CustomServerTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: SecureColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: SecureColors.surfaceDarkSlate,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: SecureColors.textPrimary,
          fontFamily: 'Inter',
          fontSize: 14.0,
        ),
        cursorColor: SecureColors.cyberBlue,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.dns_outlined,
            color: SecureColors.textSecondary,
            size: 18.0,
          ),
          hintText: 'matrix.org (Default Node)',
          hintStyle: const TextStyle(
            color: SecureColors.textSecondary,
            fontSize: 14.0,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final isCustom = value.text.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  Icons.circle,
                  size: 8.0,
                  color: isCustom ? SecureColors.cyberBlue : SecureColors.textSecondary,
                ),
              );
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          border: InputBorder.none,
        ),
      ),
    );
  }
}