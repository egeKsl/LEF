// lib/features/chat_room/presentation/widgets/message_list.dart
//
// LAYER: features/chat_room/presentation
// RESPONSIBILITY: Renders a list of MessageEnvelope bubbles.
//
// Pure UI — receives a List<MessageEnvelope> and renders it.
// No network, no storage, no encryption knowledge.

import 'package:flutter/material.dart';
import '../../../../core/messaging/message_envelope.dart';
import '../../../../theme/secure_colors.dart';

class MessageList extends StatelessWidget {
  final List<MessageEnvelope> messages;

  const MessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'NO MESSAGES YET\n// SEND THE FIRST ONE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SecureColors.textSecondary,
            fontFamily: 'Inter',
            fontSize: 11.0,
            letterSpacing: 1.0,
            height: 1.6,
          ),
        ),
      );
    }

    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return ListView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _MessageBubble(
          envelope: msg,
          maxWidth: maxBubbleWidth,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEnvelope envelope;
  final double maxWidth;

  const _MessageBubble({required this.envelope, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final isMe = envelope.isOutgoing;
    final body = envelope.plaintextBody ?? '[encrypted]';
    final time = '${envelope.timestamp.toLocal().hour.toString().padLeft(2, '0')}:'
        '${envelope.timestamp.toLocal().minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              constraints: BoxConstraints(maxWidth: maxWidth),
              decoration: BoxDecoration(
                color: isMe
                    ? SecureColors.surfaceDarkSlate
                    : SecureColors.surfaceCharcoal,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                body,
                style: const TextStyle(
                  color: SecureColors.textPrimary,
                  fontFamily: 'Inter',
                  fontSize: 14.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 9.0,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon(envelope.status),
                    size: 10,
                    color: _statusColor(envelope.status),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(DeliveryStatus s) => switch (s) {
        DeliveryStatus.pending => Icons.schedule,
        DeliveryStatus.sent => Icons.check,
        DeliveryStatus.delivered => Icons.done_all,
        DeliveryStatus.failed => Icons.error_outline,
      };

  Color _statusColor(DeliveryStatus s) => switch (s) {
        DeliveryStatus.pending => SecureColors.textSecondary,
        DeliveryStatus.sent => SecureColors.textSecondary,
        DeliveryStatus.delivered => SecureColors.cryptoGreen,
        DeliveryStatus.failed => SecureColors.panicRed,
      };
}
