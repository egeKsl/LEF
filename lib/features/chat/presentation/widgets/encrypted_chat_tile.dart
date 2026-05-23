import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class EncryptedChatTile extends StatelessWidget {
  final String roomName;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isEncrypted;
  final VoidCallback onTap;

  const EncryptedChatTile({
    super.key,
    required this.roomName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.isEncrypted = true, // Default to true for zero-knowledge privacy enforcement
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: SecureColors.surfaceCharcoal,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: SecureColors.surfaceCharcoal,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Structural Cryptographic Avatar/Status Anchor
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SecureColors.surfaceCharcoal,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Icon(
                  isEncrypted ? Icons.lock_outline : Icons.lock_open_outlined,
                  color: isEncrypted ? SecureColors.cryptoGreen : SecureColors.panicRed,
                  size: 18.0,
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Meta-Data Content Node Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          roomName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SecureColors.textPrimary,
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: SecureColors.textSecondary,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SecureColors.textSecondary,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SecureColors.cyberBlue,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: SecureColors.textPrimary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}