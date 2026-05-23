import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix/matrix.dart' as matrix;
import '../../../auth/data/matrix_auth_service.dart';
import '../../data/mock_chat_data.dart';
import '../../../../theme/secure_colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../chat_room/presentation/screens/chat_room_screen.dart';
import '../widgets/status_app_bar.dart';
import '../widgets/encrypted_chat_tile.dart';
import '../widgets/new_chat_modal.dart';

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '--:--';
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// FAB sits just above the system nav bar with equal side/bottom margins.
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
    final y = scaffoldSize.height -
        fabSize.height -
        insets.bottom -
        _bottomMargin;

    return Offset(x, y);
  }
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Widget _buildChatList({
    required double bottomInset,
    required double fabClearance,
    required List<EncryptedChatTile> tiles,
  }) {
    if (tiles.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + fabClearance),
          child: const Text(
            "NO ACTIVE CRYPTO-CHANNELS\n// TAP FAB TO INITIALIZE",
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
      padding: EdgeInsets.only(bottom: bottomInset + fabClearance),
      itemCount: tiles.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) => tiles[index],
    );
  }

  void _openChatRoom(BuildContext context, {MockChatPreview? mock, matrix.Room? room}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(mockPreview: mock, room: room),
      ),
    );
  }

  List<EncryptedChatTile> _tilesFromMock(BuildContext context) {
    return mockChatPreviews
        .map(
          (item) => EncryptedChatTile(
            roomName: item.roomName,
            lastMessage: item.lastMessage,
            timestamp: item.timestamp,
            unreadCount: item.unreadCount,
            isEncrypted: item.isEncrypted,
            onTap: () => _openChatRoom(context, mock: item),
          ),
        )
        .toList();
  }

  List<EncryptedChatTile> _tilesFromRooms(BuildContext context, List<matrix.Room> rooms) {
    return rooms
        .map(
          (room) => EncryptedChatTile(
            roomName: room.getLocalizedDisplayname(),
            lastMessage: room.lastEvent?.body ?? "EMPTY_CHANNEL_LOG",
            timestamp: _formatTimestamp(room.lastEvent?.originServerTs),
            unreadCount: room.notificationCount,
            isEncrypted: room.encrypted,
            onTap: () => _openChatRoom(context, room: room),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<MatrixAuthService>(context, listen: false);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const fabClearance = 56.0 + _SecureFabLocation._bottomMargin + 20.0;

    return Scaffold(
      backgroundColor: SecureColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(StatusAppBar.height(context)),
        child: StatusAppBar(
          syncStatus: "CONNECTED",
          onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ),
      body: SafeArea(
        top: false,
        child: kUseMockChatPreview
            ? _buildChatList(
                bottomInset: bottomInset,
                fabClearance: fabClearance,
                tiles: _tilesFromMock(context),
              )
            : StreamBuilder<matrix.SyncUpdate>(
                stream: authService.client.onSync.stream,
                builder: (context, snapshot) {
                  return _buildChatList(
                    bottomInset: bottomInset,
                    fabClearance: fabClearance,
                    tiles: _tilesFromRooms(context, authService.client.rooms),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: const _SecureFabLocation(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SecureColors.textPrimary,
        foregroundColor: SecureColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        onPressed: () => NewChatModal.show(context),
        child: const Icon(Icons.add, size: 24.0),
      ),
    );
  }
}