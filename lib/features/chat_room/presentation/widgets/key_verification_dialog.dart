import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class KeyVerificationDialog extends StatelessWidget {
  final String remoteUserId;
  final List<String> sasEmojis;

  const KeyVerificationDialog({
    super.key,
    required this.remoteUserId,
    required this.sasEmojis,
  });

  /// Shows the verification dialog.
  /// Returns:
  /// - `true` if match confirmed
  /// - `false` if reported mismatch
  /// - `null` if aborted/canceled
  static Future<bool?> show(
    BuildContext context, {
    required String remoteUserId,
    List<String>? sasEmojis,
  }) {
    final List<String> defaultEmojis = sasEmojis ?? ['🐶', '🌲', '🚢', '🔑', '🎵', '🌙', '⚡'];

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return KeyVerificationDialog(
          remoteUserId: remoteUserId,
          sasEmojis: defaultEmojis,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SecureColors.surfaceCharcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: const BorderSide(color: SecureColors.cyberBlue, width: 1.0),
      ),
      title: const Row(
        children: [
          Icon(Icons.verified_user, color: SecureColors.cyberBlue, size: 20),
          SizedBox(width: 8),
          Text(
            "VERIFY_SESSION_KEYS",
            style: TextStyle(
              color: SecureColors.textPrimary,
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "REMOTE_USER_ID: $remoteUserId",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SecureColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list of the SAS emojis
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: sasEmojis.map((emoji) {
                return Container(
                  margin: const EdgeInsets.only(right: 6.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: SecureColors.background,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: SecureColors.surfaceDarkSlate, width: 1.0),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22.0),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Compare the emojis above with the symbols displayed on the remote peer device. If they match exactly, confirm session trust.",
            style: TextStyle(
              color: SecureColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 11.0,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            "ABORT",
            style: TextStyle(
              color: SecureColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SecureColors.panicRed, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "REPORT_MISMATCH",
                style: TextStyle(
                  color: SecureColors.panicRed,
                  fontFamily: 'Inter',
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SecureColors.cryptoGreen,
                foregroundColor: SecureColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "CONFIRM_MATCH",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
