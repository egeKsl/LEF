import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class KeyManagementCards extends StatelessWidget {
  final VoidCallback onExportKeys;
  final VoidCallback onImportKeys;

  const KeyManagementCards({
    super.key,
    required this.onExportKeys,
    required this.onImportKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: SecureColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: SecureColors.surfaceDarkSlate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 16, color: SecureColors.cyberBlue),
              SizedBox(width: 8),
              Text(
                "CRYPTOGRAPHIC_KEY_STORE",
                style: TextStyle(
                  color: SecureColors.textPrimary,
                  fontFamily: 'Inter',
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Export raw End-to-End Encryption session logs or map legacy database keys. Keep target configurations offline.",
            style: TextStyle(color: SecureColors.textSecondary, fontSize: 11.0, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportKeys,
                  icon: const Icon(Icons.file_upload_outlined, size: 14),
                  label: const Text("EXPORT_KEYS", style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SecureColors.textPrimary,
                    side: const BorderSide(color: SecureColors.surfaceDarkSlate),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImportKeys,
                  icon: const Icon(Icons.file_download_outlined, size: 14),
                  label: const Text("IMPORT_KEYS", style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SecureColors.cyberBlue,
                    side: const BorderSide(color: SecureColors.surfaceDarkSlate),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}