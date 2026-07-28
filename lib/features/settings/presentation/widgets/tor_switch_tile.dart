import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class TorSwitchTile extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const TorSwitchTile({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: SecureColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: isActive ? SecureColors.cryptoGreen : SecureColors.surfaceDarkSlate,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.router_outlined,
                      size: 16,
                      color: isActive ? SecureColors.cryptoGreen : SecureColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "TOR_PROXY_TUNNELING",
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
                const SizedBox(height: 4),
                const Text(
                  "Route outbound payloads through decentralized Onion networks. May increase latent delivery intervals.",
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 11.0,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: isActive,
            activeTrackColor: SecureColors.cryptoGreen,
            inactiveTrackColor: SecureColors.surfaceDarkSlate,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}