import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class PanicButton extends StatelessWidget {
  final VoidCallback onZeroizeConfirmed;

  const PanicButton({super.key, required this.onZeroizeConfirmed});

  void _triggerPanicSequence(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: SecureColors.surfaceCharcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
            side: const BorderSide(color: SecureColors.panicRed, width: 1.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: SecureColors.panicRed),
              SizedBox(width: 8),
              Text(
                "CONFIRM_ZEROIZE_PROTOCOL",
                style: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter', fontSize: 14.0, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: const Text(
            "This action instantly executes structural database deletion routines. All localized database states, configuration mappings, Hive stores, caches, and unique system signatures will be purged immediately. This operation is absolute and irreversible.",
            style: TextStyle(color: SecureColors.textSecondary, fontSize: 12.0, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ABORT", style: TextStyle(color: SecureColors.textPrimary, fontSize: 12.0)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: SecureColors.panicRed),
              onPressed: () {
                Navigator.pop(context);
                onZeroizeConfirmed();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "EXECUTE PURGE",
                  style: TextStyle(color: SecureColors.textPrimary, fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _triggerPanicSequence(context),
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0505),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: SecureColors.panicRed, width: 1.0),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever_outlined, color: SecureColors.panicRed, size: 20),
              SizedBox(width: 10),
              Text(
                "EXECUTE PANIC PROTOCOL (ZEROIZE)",
                style: TextStyle(
                  color: SecureColors.panicRed,
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}