## 2026-07-27T20:58:53Z
You are Explorer 3 for Milestone 4 (UI Features & BLoCs Integration - Chat Room & App Wiring).
Your working directory is /home/tommy/messaging/.agents/explorer_m4_3.

Objectives:
1. Examine all files in `lib/features/chat_room/` and `lib/main.dart` (plus any dependency injection / locator / app initialization files).
2. Map out how `ChatRoomScreen` and `ChatRoomBloc` / `ChatRoomCubit` should be refactored to:
   - Load real message history (`MessageEnvelope`) from `LocalStorageRepository`.
   - Send encrypted messages by constructing `MessageEnvelope`, saving to `LocalStorageRepository`, and passing to `RelayTransportAdapter.sendEnvelope`.
   - Listen to incoming message streams and update the UI in real-time.
3. Map out how `lib/main.dart` and global app initialization should be refactored to:
   - Initialize `OfflineIdentityService`, `LocalStorageRepository`, and `RelayTransportAdapter`.
   - Wire dependencies cleanly into BLoCs/Providers at the root of the app.
   - Direct app flow to Auth/Identity screen if no local identity exists, or ChatListScreen if identity exists.
4. Verify strict layered architecture compliance across all UI components.

Deliver your detailed refactoring plan and code analysis in `/home/tommy/messaging/.agents/explorer_m4_3/handoff.md`.
