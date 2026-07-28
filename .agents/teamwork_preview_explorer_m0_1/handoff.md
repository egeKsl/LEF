# Handoff Report: Legacy P2P, Matrix, and Mock Data Investigation

## 1. Observation

### 1.1 P2P Infrastructure
- **`lib/core/p2p/p2p_node_service.dart`**:
  - `P2pMessage` (L5-35): Data model (`id`, `senderId`, `recipientId`, `body`, `timestamp`).
  - `P2pPeer` (L37-49): Peer model (`userId`, `ipAddress`, `port: 8008`, `lastSeen`).
  - `P2pNodeService` (L52-288): Singleton daemon. Listens on `InternetAddress.anyIPv4` port `8008` (L92). Handles endpoints `/p2p/handshake` (L134), `/p2p/message` (L155), `/p2p/status` (L174). Outbound calls: `sendHandshakeToIp` (L206), `sendMessage` (L234). Default ID domain: `'@local_peer:yggdrasil'` (L62).
- **Import Locations**:
  - `lib/features/auth/presentation/bloc/auth_bloc.dart` (L4): `import '../../../../core/p2p/p2p_node_service.dart';` — calls `setCurrentUserId` at lines 62, 75, 90, 105.
  - `lib/features/chat/presentation/widgets/new_chat_modal.dart` (L11): `import '../../../../core/p2p/p2p_node_service.dart';` — calls `getPeerIp` (L181), `sendHandshakeToIp` (L184), `registerPeer` (L221).
  - `lib/features/chat_room/presentation/screens/chat_room_screen.dart` (L4): `import '../../../../core/p2p/p2p_node_service.dart';` — subscribes to `onMessageReceived` (L55) and calls `sendMessage` (L88).

### 1.2 Mock Data Infrastructure
- **`lib/features/chat/data/mock_chat_data.dart`**:
  - `kUseMockChatPreview = true;` (L2).
  - `class MockChatPreview` (L4-18) & `mockChatPreviews` (L20-62) with 7 mock entries.
- **`lib/features/chat_room/data/mock_chat_room_messages.dart`**:
  - `kUseMockChatRoomMessages = true;` (L2).
  - `class MockMessage` (L4-16) & `_messagesByRoom` map (L40-140).
- **`lib/features/chat/presentation/screens/chat_list_screen.dart`**:
  - `kDisableMocksForProduction = false;` (L15).
  - Line 134-149: `kDisableMocksForProduction ? _buildChatList(..., tiles: _tilesFromMock(context)) : StreamBuilder<matrix.SyncUpdate>(..., tiles: _tilesFromRooms(context, authService.client.rooms))`

### 1.3 Matrix Integration & SDK
- **`pubspec.yaml`**: Line 37 `matrix: 7.1.2`.
- **`lib/features/auth/data/matrix_auth_service.dart`**:
  - `import 'package:matrix/matrix.dart';` (L3).
  - `class MatrixAuthService` (L8) wrapping Matrix `Client` (L11, L14, L34) with SQLite database `secure_matrix_store` (L28).
- **Imports in UI/Bloc**:
  - `auth_bloc.dart:2`, `auth_screen.dart:8`, `chat_list_screen.dart:4`, `new_chat_modal.dart:7`, `settings_screen.dart:6`, `main.dart:6`.
- **Symbols**:
  - `matrix.Client`: `authService.client` accessed in `chat_list_screen.dart:141,146`, `new_chat_modal.dart:246`.
  - `matrix.Room`: `chat_list_screen.dart:78,102`, `chat_room_screen.dart:14`, `message_stream.dart:7`.
  - `matrix.Timeline`: `message_stream.dart:16,25`.
  - `matrix.SyncUpdate`: `chat_list_screen.dart:140`.

### 1.4 String Literals (`yggdrasil`, `127.0.0.1`, `loopback`, `8008`)
- `yggdrasil`:
  - `p2p_node_service.dart:62`: `@local_peer:yggdrasil`
  - `mock_chat_data.dart:28`: `@alice:yggdrasil`
  - `new_chat_modal.dart:45`: `homeserver == 'yggdrasil'`
  - `mock_chat_room_messages.dart:63`: `'@alice:yggdrasil': [...]`
  - `chat_room_screen.dart:179`: `remoteId = _useMock ? '@alice:yggdrasil' : _roomName;`
- `127.0.0.1`:
  - `p2p_node_service.dart:117`: IP discovery fallback.
  - `matrix_auth_service.dart:65`: URL scheme prefix check.
- `loopback`:
  - `p2p_node_service.dart:111`: `!addr.isLoopback`
  - `auth_screen.dart:240`: User notice string.
  - `new_chat_modal.dart:268,271`: Code comment and `LOOPBACK_NODE_UNREACHABLE` string match in catch block.
- `8008`:
  - `p2p_node_service.dart:46,59,85`: Default port assignment and comments.

### 1.5 Modal Helpers (`new_chat_modal.dart`)
- `_isServerlessPeerTarget(String targetId)` (L29-50): Returns `true` if target ID has no colon, ends with `.yggdrasil`, or contains an IPv4/non-domain homeserver. Invoked at L180 and evaluated at L202.
- `_buildP2pPreview(String targetId)` (L52-60): Returns a `MockChatPreview` with title `targetId` and `lastMessage: "P2P ENCRYPTED LINK ESTABLISHED"`. Invoked at L228.

---

## 2. Logic Chain

1. **Dual Network Paradigm**:
   - The application supports two distinct communication transport paths:
     1) Matrix homeserver protocol via `MatrixAuthService` / `matrix.Client` (`package:matrix/matrix.dart`).
     2) Direct socket Wi-Fi P2P HTTP server on port 8008 via `P2pNodeService` (`lib/core/p2p/p2p_node_service.dart`).
2. **Modal Routing & Handshake**:
   - `new_chat_modal.dart` uses `_isServerlessPeerTarget` to determine whether a target Matrix ID / IP should be routed directly to the P2P socket mesh or through the Matrix homeserver (`authService.client.createRoom`).
   - When routed to P2P, `_buildP2pPreview` constructs a `MockChatPreview` adapter object so `ChatRoomScreen` can render mock streams while listening to `P2pNodeService.onMessageReceived`.
3. **Mock Data Dual Utility**:
   - Mock structures (`MockChatPreview`, `MockMessage`, `mockChatPreviews`, `mockMessagesForRoom`) are used both for static offline demo presentation and as runtime container objects for P2P messages when live Matrix rooms are bypassed.
4. **Toggles and Live Wiring**:
   - `kDisableMocksForProduction` (in `chat_list_screen.dart:15`) dictates whether `ChatListScreen` displays `mockChatPreviews` or streams `authService.client.rooms`. Currently set to `false`, which enables live Matrix room streaming.

---

## 3. Caveats

- No caveats. Scope was read-only investigation across `lib/` and `pubspec.yaml` and was fully satisfied without unexamined areas.

---

## 4. Conclusion

All references to P2P services (`P2pNodeService`, `P2pPeer`, `P2pMessage`, `p2p_node_service.dart`), Mock structures (`mock_chat_data.dart`, `mock_chat_room_messages.dart`, `MockChatPreview`, `MockMessage`, `kUseMockChatPreview`, `kDisableMocksForProduction`), Matrix SDK dependencies (`MatrixAuthService`, `matrix.Client`, `matrix.Room`, `matrix.Timeline`, `matrix.SyncUpdate`), specific network string literals (`yggdrasil`, `127.0.0.1`, `loopback`, `8008`), and modal helpers (`_isServerlessPeerTarget`, `_buildP2pPreview`) have been identified, verified, and mapped with exact line numbers and code snippets in `analysis.md`.

---

## 5. Verification Method

To independently verify these findings:
1. Inspect `/home/tommy/messaging/.agents/teamwork_preview_explorer_m0_1/analysis.md` for the complete itemized search tables and code line citations.
2. Run grep commands across `/home/tommy/messaging/lib/`:
   - `grep -rn "P2pNodeService" lib/`
   - `grep -rn "MockChatPreview" lib/`
   - `grep -rn "MatrixAuthService" lib/`
   - `grep -rn "yggdrasil" lib/`
   - `grep -rn "_isServerlessPeerTarget" lib/`
3. Verify file paths and line numbers against `/home/tommy/messaging/lib/`.
