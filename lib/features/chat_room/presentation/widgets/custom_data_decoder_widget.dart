import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';
import '../../data/isolate_decoder_service.dart';

class CustomDataDecoderWidget extends StatelessWidget {
  final String rawEncodedPayload;

  const CustomDataDecoderWidget({
    super.key,
    required this.rawEncodedPayload,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: IsolateDecoderService.decodeCustomVisualData(rawEncodedPayload),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: SecureColors.surfaceCharcoal,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0505),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: SecureColors.panicRed, width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, color: SecureColors.panicRed, size: 16),
                SizedBox(width: 8),
                Text(
                  "DECRYPTION_ISOLATE_FAILED",
                  style: TextStyle(color: SecureColors.panicRed, fontSize: 11.0, fontFamily: 'Inter'),
                ),
              ],
            ),
          );
        }

        // Successfully cleared the isolate thread pipelines
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            color: SecureColors.surfaceCharcoal,
            child: Image.memory(
              snapshot.data!,
              width: 240,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("MALFORMED_DATA_STREAM", style: TextStyle(color: SecureColors.textSecondary)),
              ),
            ),
          ),
        );
      },
    );
  }
}