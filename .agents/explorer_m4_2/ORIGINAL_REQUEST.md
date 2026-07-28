## 2026-07-27T20:58:53Z
You are Explorer 2 for Milestone 4 (UI Features & BLoCs Integration - Chat List & New Chat Modal).
Your working directory is /home/tommy/messaging/.agents/explorer_m4_2.

Objectives:
1. Examine all files in `lib/features/chat/` and `lib/features/chat/presentation/widgets/new_chat_modal.dart`.
2. Map out how `ChatListBloc` / `ChatListCubit` and `ChatListScreen` should be refactored to:
   - Fetch real conversation entities (`Conversation`) from `LocalStorageRepository` (`lib/core/storage/local_storage_repository.dart`).
   - Remove any mock tile fallbacks or dead legacy structures.
   - Listen to real-time incoming transport envelopes and local storage updates to dynamically refresh conversation list and unread counts.
3. Map out how `NewChatModal` should be refactored to:
   - Accept contact public key fingerprint (Base58/Base64) + optional relay URL hint.
   - Validate fingerprint via `ContactAddress.isValidFingerprint`.
   - Save valid contacts into `LocalStorageRepository`.
   - Remove any remaining IP address input fields or legacy P2P target selectors.
4. Ensure UI widgets do not import transport or storage directly (UI -> Domain/BLoC -> Data).

Deliver your detailed refactoring plan and code analysis in `/home/tommy/messaging/.agents/explorer_m4_2/handoff.md`.
