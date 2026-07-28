# Project Plan: SimpleX-Inspired Flutter Messaging Application

## Architecture Overview
Layered architecture: UI (`lib/features/`) -> Domain (`lib/core/identity/`, `lib/core/addressing/`, `lib/core/messaging/`) -> Data (`lib/core/transport/`, `lib/core/storage/`).
Strict unidirectional dependency rule: UI depends only on Domain (and BLoC/Repository interfaces), Data implements Domain interfaces, no reverse dependencies. Zero direct transport/storage imports in UI.

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 0 | Exploration & Architecture Map | Map current codebase, dependencies, imports, state management | None | DONE |
| 1 | Core Domain Layer | `lib/core/identity/`, `lib/core/addressing/`, `lib/core/messaging/` | M0 | DONE |
| 2 | Transport & Storage Data Layer | `lib/core/transport/`, `lib/core/storage/` | M1 | DONE |
| 3 | Legacy Path & Matrix Removal | Delete dead P2P/mock/matrix code, update `pubspec.yaml` | M1, M2 | DONE |
| 4 | UI & Feature Layer Decoupling | `lib/features/` (auth/identity, chat list, room, settings) | M1, M2, M3 | IN_PROGRESS |
| 5 | E2E Testing & Forensic Audit | Verification, `flutter analyze`, `flutter build apk`, audit | M4 | PLANNED |

## Milestone 4 Objectives (For Successor)
1. **Auth & Identity Onboarding UI & BLoC (`lib/features/auth/` or `lib/features/identity/`)**:
   - `AuthBloc` / `IdentityBloc`: Handles `CreateLocalIdentityRequested`, `ImportIdentityRequested`, `LoadIdentityRequested`.
   - UI screen: Offline keypair identity creation / import dialog with QR code scanner and export option. No Matrix user ID syntax (`@user:server`).
2. **Chat List UI & BLoC (`lib/features/chat/`)**:
   - `ChatListBloc` / `ChatListCubit`: Interacts with `LocalStorageRepository` to display real local conversations (no mock data).
   - Dynamic real-time updates when messages arrive via `TransportAdapter` and `LocalStorageRepository`.
3. **Chat Room UI & BLoC (`lib/features/chat_room/`)**:
   - `ChatRoomBloc` / `ChatRoomCubit`: Displays real message history from `LocalStorageRepository`, sends encrypted `MessageEnvelope`s through `RelayTransportAdapter` and updates local storage.
4. **New Chat Modal (`lib/features/chat/presentation/widgets/new_chat_modal.dart`)**:
   - Accepts contact public key fingerprint (Base58/Base64), not IP address or Matrix ID.
   - Inserts contact into `LocalStorageRepository`.
5. **Settings Screen (`lib/features/settings/`)**:
   - Add Relay Server URL configuration input field (`RelayTransportAdapter` URL).
   - Display active relay server URL and connection status (`disconnected`, `connecting`, `connected`, `error`).
