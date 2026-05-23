import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';
import '../../data/mock_chat_room_messages.dart';
import 'custom_data_decoder_widget.dart';

class MockMessageStream extends StatelessWidget {
  final List<MockMessage> messages;

  const MockMessageStream({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return ListView.builder(
      itemCount: messages.length,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.isMe;

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
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  decoration: BoxDecoration(
                    color: isMe
                        ? SecureColors.surfaceDarkSlate
                        : SecureColors.surfaceCharcoal,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: message.isCustomEncoded
                      ? const CustomDataDecoderWidget(
                          rawEncodedPayload: '',
                        )
                      : Text(
                          message.body,
                          style: const TextStyle(
                            color: SecureColors.textPrimary,
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.time,
                  style: const TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
