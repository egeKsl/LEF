## 2026-07-28T00:10:05Z

You are Worker M4 for Milestone 4 (UI Features & BLoCs Integration).
Your working directory is /home/tommy/messaging/.agents/worker_m4.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context and Instructions:
Please read the detailed exploration reports from the 3 Explorers before implementing:
- `/home/tommy/messaging/.agents/explorer_m4_1/handoff.md` (Auth & Settings UI & BLoCs)
- `/home/tommy/messaging/.agents/explorer_m4_2/handoff.md` (Chat List & New Chat Modal)
- `/home/tommy/messaging/.agents/explorer_m4_3/handoff.md` (Chat Room & App Wiring)
- `/home/tommy/messaging/.agents/orchestrator/PROJECT.md`
- `/home/tommy/messaging/.agents/ORIGINAL_REQUEST.md`

Your tasks for Milestone 4:
1. **Auth Feature (`lib/features/auth/`)**:
   - Refactor `AuthBloc` and `AuthScreen` to manage local offline identity generation and import via `OfflineIdentityService`.
   - Remove login/register, homeserver URL, username, password, and Matrix references.
   - Screen must show Base58 keypair fingerprint, QR code display/copy, and QR import options.

2. **Settings Feature (`lib/features/settings/`)**:
   - Add `SettingsBloc` or `SettingsCubit` to manage relay URL configuration, Tor toggle, key management, and panic purge.
   - Refactor `SettingsScreen` to add a Relay Server URL input field connected to `RelayTransportAdapter` and display real-time connection status (`disconnected`, `connecting`, `connected`, `error`).
   - Remove direct instantiation/imports of `LocalStorageRepository` or `DatabaseService` in `SettingsScreen`.

3. **Chat List Feature (`lib/features/chat/`)**:
   - Implement `ChatListBloc` and `NewChatCubit`.
   - `ChatListBloc` subscribes to `TransportAdapter.incomingEnvelopes` and `TransportAdapter.connectionState`, updating stored conversations from `LocalStorageRepository`.
   - `ChatListScreen` consumes `ChatListBloc` (no direct `LocalStorageRepository` calls or `FutureBuilder` reloading).
   - `NewChatModal` accepts contact Base58/Base64 public key fingerprint (validated via `ContactAddress.isValidFingerprint`), optional Relay Server URL hint, and creates initial contact/conversation via `NewChatCubit`. Update `StatusAppBar` title to remove legacy `"MATRIX PROTOCOL NODE"`.

4. **Chat Room Feature (`lib/features/chat_room/`)**:
   - Implement `ChatRoomBloc` to manage message history, payload encryption/decryption (`E2eCryptoService`), sending via `RelayTransportAdapter.sendEnvelope()`, saving via `LocalStorageRepository.saveEnvelope()`, and listening to `TransportAdapter.incomingEnvelopes`.
   - Refactor `ChatRoomScreen` and `MessageStream` to render decrypted messages via `BlocBuilder` without direct `LocalStorageRepository` calls or `FutureBuilder`.

5. **App Wiring & Global Injection (`lib/main.dart`)**:
   - Initialize `LocalStorageRepository`, `OfflineIdentityService`, `RelayTransportAdapter`, and `PlaceholderE2eCryptoService`.
   - Connect `RelayTransportAdapter` on startup.
   - Provide repositories and services via `MultiProvider` at the root, setup BLoCs in route generation (`AppRoutes`), and direct initial route cleanly based on identity presence.

6. **Architecture Boundary Enforcement**:
   - Ensure ZERO UI files in `lib/features/*/presentation/` import `lib/core/storage/` or `lib/core/transport/` directly.

7. **Verification**:
   - Run `flutter analyze` and verify 0 errors.
   - Run `flutter test` and verify all tests pass. Update/add unit and BLoC tests as needed.

Deliver your handoff report in `/home/tommy/messaging/.agents/worker_m4/handoff.md` with command execution logs and build/test outputs.
