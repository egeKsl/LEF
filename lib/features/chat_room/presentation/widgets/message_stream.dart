import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import '../../../../theme/secure_colors.dart';
import 'custom_data_decoder_widget.dart';

class MessageStream extends StatefulWidget {
  final matrix.Room room;

  const MessageStream({super.key, required this.room});

  @override
  State<MessageStream> createState() => _MessageStreamState();
}

class _MessageStreamState extends State<MessageStream> {
  matrix.Timeline? _timeline;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final timeline = await widget.room.getTimeline(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) {
      setState(() => _timeline = timeline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timeline == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
          ),
        ),
      );
    }

    final messages = _timeline!.events
        .where((e) => e.type == matrix.EventTypes.Message)
        .toList();

    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return ListView.builder(
      itemCount: messages.length,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemBuilder: (context, index) {
        final event = messages[index];
        final isMe = event.senderId == widget.room.client.userID;
        final isCustomEncodedVisual =
            event.body.startsWith('CUSTOM_HEX_RAW://');

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
                  child: isCustomEncodedVisual
                      ? CustomDataDecoderWidget(
                          rawEncodedPayload: event.body.replaceFirst(
                            'CUSTOM_HEX_RAW://',
                            '',
                          ),
                        )
                      : Text(
                          event.body,
                          style: const TextStyle(
                            color: SecureColors.textPrimary,
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.originServerTs.toIso8601String().substring(11, 16),
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
