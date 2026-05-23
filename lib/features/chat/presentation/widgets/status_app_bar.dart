import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class StatusAppBar extends StatelessWidget {
  final String syncStatus;
  final bool isTorActive;

  const StatusAppBar({
    super.key,
    required this.syncStatus,
    this.isTorActive = false,
  });

  /// Total app bar height: status bar (notch/camera) + toolbar content.
  static double height(BuildContext context) {
    return MediaQuery.paddingOf(context).top + kToolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        color: SecureColors.background,
        border: Border(
          bottom: BorderSide(
            color: SecureColors.surfaceCharcoal,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset),
          SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "MATRIX PROTOCOL NODE",
                          style: TextStyle(
                            color: SecureColors.textSecondary,
                            fontSize: 9.0,
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: SecureColors.cryptoGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                syncStatus.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SecureColors.textPrimary,
                                  fontFamily: 'Inter',
                                  fontSize: 13.0,
                                  height: 1.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: SecureColors.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: isTorActive
                            ? SecureColors.cryptoGreen
                            : SecureColors.surfaceDarkSlate,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security,
                          size: 12.0,
                          color: isTorActive
                              ? SecureColors.cryptoGreen
                              : SecureColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTorActive ? "TOR: ACTIVE" : "TOR: INACTIVE",
                          style: TextStyle(
                            color: isTorActive
                                ? SecureColors.cryptoGreen
                                : SecureColors.textSecondary,
                            fontFamily: 'Inter',
                            fontSize: 10.0,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
