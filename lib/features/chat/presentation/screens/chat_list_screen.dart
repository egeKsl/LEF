// lib/features/chat/presentation/screens/chat_list_screen.dart
//
// LAYER: features/chat/presentation
// RESPONSIBILITY: Displays the conversation list.
//
// Only interacts with ChatListCubit — zero knowledge of transport, storage,
// Matrix, P2P, or mock data.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/storage_repository.dart';
import '../../../../theme/secure_colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../chat_room/presentation/screens/chat_room_screen.dart';
import '../../bloc/chat_list_cubit.dart';
import '../widgets/encrypted_chat_tile.dart';
import '../widgets/new_chat_modal.dart';
import '../widgets/status_app_bar.dart';

class _SecureFabLocation extends FloatingActionButtonLocation {
  const _SecureFabLocation();

  static const double _sideMargin = 20.0;
  static const double _bottomMargin = 22.0;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fabSize = geometry.floatingActionButtonSize;
    final scaffoldSize = geometry.scaffoldSize;
    final insets = geometry.minViewPadding;

    final x = scaffoldSize.width - fabSize.width - _sideMargin;
    final y = scaffoldSize.height - fabSize.height - insets.bottom - _bottomMargin;

    return Offset(x, y);
  }
}

class ChatListScreen extends StatefulWidget {
  final StorageRepository storage;
  const ChatListScreen({super.key, required this.storage});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatListCubit>().load();
  }

  void _openChatRoom(BuildContext context, Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(conversation: conversation),
      ),
    );
  }

  String _formatTimestamp(DateTime? ts) {
    if (ts == null) return '--:--';
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const fabClearance = 56.0 + _SecureFabLocation._bottomMargin + 20.0;

    return Scaffold(
      backgroundColor: SecureColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(StatusAppBar.height(context)),
        child: StatusAppBar(
          syncStatus: 'RELAY TRANSPORT',
          onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ChatListCubit, ChatListState>(
          builder: (context, state) {
            if (state is ChatListLoading) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
                  ),
                ),
              );
            }

            if (state is ChatListError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(
                    color: SecureColors.panicRed,
                    fontFamily: 'Inter',
                    fontSize: 11.0,
                  ),
                ),
              );
            }

            final conversations =
                state is ChatListLoaded ? state.conversations : <Conversation>[];

            if (conversations.isEmpty) {
              return Center(
                child: Padding(
                  padding:
                      EdgeInsets.only(bottom: bottomInset + fabClearance),
                  child: const Text(
                    'NO CONVERSATIONS\n// TAP + TO START ONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SecureColors.textSecondary,
                      fontFamily: 'Inter',
                      fontSize: 11.0,
                      letterSpacing: 1.0,
                      height: 1.6,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding:
                  EdgeInsets.only(bottom: bottomInset + fabClearance),
              itemCount: conversations.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return EncryptedChatTile(
                  roomName: conv.contact.label,
                  lastMessage: conv.lastMessage?.plaintextBody ??
                      'ENCRYPTED CHANNEL',
                  timestamp:
                      _formatTimestamp(conv.lastMessage?.timestamp.toLocal()),
                  unreadCount: conv.unreadCount,
                  isEncrypted: true,
                  onTap: () => _openChatRoom(context, conv),
                );
              },
            );
          },
        ),
      ),
      floatingActionButtonLocation: const _SecureFabLocation(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SecureColors.textPrimary,
        foregroundColor: SecureColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        onPressed: () async {
          final cubit = context.read<ChatListCubit>();
          await NewChatModal.show(context, widget.storage);
          if (mounted) cubit.load();
        },
        child: const Icon(Icons.add, size: 24.0),
      ),
    );
  }
}