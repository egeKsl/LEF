// lib/features/chat_room/presentation/screens/chat_room_screen.dart
//
// LAYER: features/chat_room/presentation
// RESPONSIBILITY: Message thread UI for a single conversation.
//
// Reads messages from ChatRoomCubit. Sends via the same cubit.
// No P2P, no Matrix, no mock data, no direct transport access.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/messaging/conversation.dart';
import '../../../../core/messaging/message_envelope.dart';
import '../../../../theme/secure_colors.dart';
import '../bloc/chat_room_cubit.dart';
import '../widgets/message_list.dart';
import '../widgets/secure_input_bar.dart';
import '../widgets/key_verification_dialog.dart';

class ChatRoomScreen extends StatelessWidget {
  final Conversation conversation;

  const ChatRoomScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<ChatRoomCubit>()
        ..loadMessages(conversation.id),
      child: _ChatRoomView(conversation: conversation),
    );
  }
}

class _ChatRoomView extends StatelessWidget {
  final Conversation conversation;

  const _ChatRoomView({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatRoomCubit, ChatRoomState>(
              builder: (context, state) {
                if (state is ChatRoomLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            SecureColors.cyberBlue),
                      ),
                    ),
                  );
                }

                final messages = state is ChatRoomLoaded
                    ? state.messages
                    : <MessageEnvelope>[];

                return MessageList(messages: messages);
              },
            ),
          ),
          SecureInputBar(
            onMessageSubmitted: (body, _) async {
              final ok = await context
                  .read<ChatRoomCubit>()
                  .send(contact: conversation.contact, body: body);
              return ok;
            },
            onAttachmentTriggered: () {
              // TODO: secure file attachment pipeline
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
            conversation.contact.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SecureColors.textPrimary,
              fontSize: 14.0,
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
                decoration: const BoxDecoration(
                  color: SecureColors.cryptoGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'E2EE_ACTIVE',
                style: TextStyle(
                  color: SecureColors.cryptoGreen,
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
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
            final result = await KeyVerificationDialog.show(
              context,
              remoteUserId: conversation.contact.fingerprint,
            );
            if (result != null && context.mounted) {
              final isMatch = result == true;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: SecureColors.surfaceCharcoal,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4.0)),
                    side: BorderSide(
                      color: isMatch
                          ? SecureColors.cryptoGreen
                          : SecureColors.panicRed,
                      width: 1.0,
                    ),
                  ),
                  content: Text(
                    isMatch
                        ? 'FINGERPRINT VERIFIED // SESSION TRUSTED'
                        : 'FINGERPRINT MISMATCH // SESSION UNTRUSTED',
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
    );
  }
}
