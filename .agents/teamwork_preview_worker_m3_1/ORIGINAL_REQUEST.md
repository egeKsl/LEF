## 2026-07-27T20:18:46Z
Your working directory is /home/tommy/messaging/.agents/teamwork_preview_worker_m3_1.
Your role: Legacy Removal & Core Refinement Worker.

Objectives:

1. Apply Core Refinement Fixes in `lib/core/`:
   - `lib/core/transport/relay_transport_adapter.dart`:
     - In `connect()`, check `if (_state != TransportConnectionState.connecting) return;` after async delay.
     - In `_validateRelayUrl()`, ensure `uri.host` is non-empty and contains no `@` or `:`.
   - `lib/core/storage/database_service.dart`:
     - Enable `PRAGMA foreign_keys = ON;` in SQLite database initialization / `onConfigure`.
   - `lib/core/storage/local_storage_repository.dart`:
     - `getConversations()`: Handle missing contact gracefully (e.g. fallback `ContactAddress(fingerprint: row['contactFingerprint'])`) so missing contact record doesn't throw `StateError`.
     - `loadIdentity()`: Query with `ORDER BY createdAt DESC LIMIT 1`.
     - `saveEnvelope()`: Automatically update target conversation's `unreadCount` and `lastUpdated` timestamp in database.

2. Milestone 3 Legacy Codebase Cleanup & Matrix SDK Removal:
   - Delete files:
     - `lib/core/p2p/p2p_node_service.dart` (delete file and remove `lib/core/p2p/` directory)
     - `lib/features/chat/data/mock_chat_data.dart` (delete)
     - `lib/features/chat_room/data/mock_chat_room_messages.dart` (delete)
     - `lib/features/auth/data/matrix_auth_service.dart` (delete)
   - Update `pubspec.yaml`:
     - Remove `matrix: 7.1.2` dependency from `pubspec.yaml`
   - Remove ALL `package:matrix/...` imports from every `.dart` file.
   - Clean up ALL dead references across `lib/` and `test/`:
     - Remove `MockChatPreview`, `MockMessage`, `kUseMockChatPreview`, `kDisableMocksForProduction` identifiers.
     - Remove `P2pNodeService`, `P2pPeer`, `P2pMessage` identifiers.
     - Remove `yggdrasil`, `127.0.0.1`, `loopback`, `8008` string literals in production code paths.
     - Remove `_isServerlessPeerTarget` and `_buildP2pPreview` in `new_chat_modal.dart`.
     - Remove `MatrixAuthService`, `matrix.Client`, `matrix.Room`, `matrix.Timeline`, `matrix.SyncUpdate` references.

3. Run verification:
   - Run `flutter test test/core` and `dart analyze lib/core`. Ensure zero errors and zero broken references.
