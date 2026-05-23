import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import '../../../chat/data/mock_chat_data.dart';
import '../../../../theme/secure_colors.dart';
import '../../data/mock_chat_room_messages.dart';
import '../widgets/message_stream.dart';
import '../widgets/mock_message_stream.dart';
import '../widgets/secure_input_bar.dart';
import '../widgets/key_verification_dialog.dart';

class ChatRoomScreen extends StatefulWidget {
  final matrix.Room? room;
  final MockChatPreview? mockPreview;

  const ChatRoomScreen({
    super.key,
    this.room,
    this.mockPreview,
  }) : assert(room != null || mockPreview != null);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late List<MockMessage> _mockMessages;

  bool get _useMock => widget.mockPreview != null;

  String get _roomName =>
      widget.mockPreview?.roomName ??
      widget.room?.getLocalizedDisplayname() ??
      'SECURE_CHANNEL';

  bool get _isEncrypted =>
      widget.mockPreview?.isEncrypted ?? widget.room?.encrypted ?? true;

  String get _statusLabel => _isEncrypted
      ? 'E2EE_ACTIVE_ENCRYPTED_CHANNEL'
      : 'RELAY_OPEN_UNENCRYPTED';

  Color get _statusColor =>
      _isEncrypted ? SecureColors.cryptoGreen : SecureColors.panicRed;

  @override
  void initState() {
    super.initState();
    _mockMessages = List.of(
      mockMessagesForRoom(_roomName),
    );
  }

  void _onMockMessageSent(String message) {
    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _mockMessages.insert(
        0,
        MockMessage(body: message, time: time, isMe: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: SecureColors.background,
        elevation: 0,
        toolbarHeight: kToolbarHeight,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: SecureColors.textPrimary,
            size: 16,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _roomName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SecureColors.textPrimary,
                fontSize: 14.0,
                height: 1.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 9.0,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: SecureColors.cyberBlue,
              size: 18,
            ),
            onPressed: () async {
              final remoteId = _useMock ? '@alice:matrix.org' : _roomName;
              final result = await KeyVerificationDialog.show(
                context,
                remoteUserId: remoteId,
              );
              if (result != null && mounted) {
                final isMatch = result == true;
                final message = isMatch
                    ? "E2EE_VERIFICATION_MARKED_LOCALLY // SESSION TRUSTED"
                    : "E2EE_VERIFICATION_MARKED_LOCALLY // SESSION MISMATCH REPORTED";
                final borderColor = isMatch ? SecureColors.cryptoGreen : SecureColors.panicRed;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: SecureColors.surfaceCharcoal,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
                      side: BorderSide(color: borderColor, width: 1.0),
                    ),
                    content: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: SecureColors.textPrimary,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: SecureColors.surfaceCharcoal, width: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _useMock
                ? MockMessageStream(messages: _mockMessages)
                : MessageStream(room: widget.room!),
          ),
          SecureInputBar(
            onMessageSubmitted: (message, expiry) {
              if (_useMock) {
                _onMockMessageSent(message);
                return;
              }
              widget.room!.sendTextEvent(message);
            },
            onAttachmentTriggered: () {
              // TODO: Trigger secure file scanner extraction pipelines
            },
          ),
        ],
      ),
    );
  }
}
