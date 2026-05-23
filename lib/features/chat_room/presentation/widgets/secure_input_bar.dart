import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';

class SecureInputBar extends StatefulWidget {
  final Function(String message, int ephemeralExpirySeconds) onMessageSubmitted;
  final VoidCallback onAttachmentTriggered;

  const SecureInputBar({
    super.key,
    required this.onMessageSubmitted,
    required this.onAttachmentTriggered,
  });

  @override
  State<SecureInputBar> createState() => _SecureInputBarState();
}

class _SecureInputBarState extends State<SecureInputBar> {
  final TextEditingController _inputController = TextEditingController();
  
  // Self-destruct time options: 0 (Off), 5 seconds, 1 minute, 1 hour
  final List<int> _ephemeralIntervals = [0, 5, 60, 3600];
  final List<String> _ephemeralLabels = ["IMMORTAL", "5 SEC", "1 MIN", "1 HR"];
  int _currentTimerIndex = 0;

  void _cycleTimerState() {
    setState(() {
      _currentTimerIndex = (_currentTimerIndex + 1) % _ephemeralIntervals.length;
    });
  }

  void _handleSend() {
    if (_inputController.text.trim().isEmpty) return;
    widget.onMessageSubmitted(
      _inputController.text.trim(),
      _ephemeralIntervals[_currentTimerIndex],
    );
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isEphemeralActive = _currentTimerIndex > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: SecureColors.background,
        border: Border(top: BorderSide(color: SecureColors.surfaceCharcoal, width: 1.0)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Structural Attachment Hook Anchor
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: SecureColors.textSecondary, size: 22),
              onPressed: widget.onAttachmentTriggered,
              splashColor: Colors.transparent,
            ),
            
            // Ephemerality Configuration State Selector
            GestureDetector(
              onTap: _cycleTimerState,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isEphemeralActive ? const Color(0xFF1A0505) : SecureColors.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(2.0),
                  border: Border.all(
                    color: isEphemeralActive ? SecureColors.panicRed : SecureColors.surfaceDarkSlate,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 11,
                      color: isEphemeralActive ? SecureColors.panicRed : SecureColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _ephemeralLabels[_currentTimerIndex],
                      style: TextStyle(
                        color: isEphemeralActive ? SecureColors.panicRed : SecureColors.textSecondary,
                        fontFamily: 'Inter',
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            
            // Input Text Capture Layer
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: SecureColors.textPrimary, fontSize: 14.0, fontFamily: 'Inter'),
                cursorColor: SecureColors.cyberBlue,
                decoration: const InputDecoration(
                  hintText: "Transmit secure package...",
                  hintStyle: TextStyle(color: SecureColors.textSecondary, fontSize: 13.0),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                ),
              ),
            ),
            
            // Command Dispatch Anchor
            IconButton(
              icon: const Icon(Icons.arrow_upward, color: SecureColors.cyberBlue, size: 20),
              onPressed: _handleSend,
              splashColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}