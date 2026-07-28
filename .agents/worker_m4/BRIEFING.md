# BRIEFING — 2026-07-28T00:10:05Z

## Mission
Implement Milestone 4: Refactor Auth, Settings, Chat List, and Chat Room UI features to use BLoC state management, connect to core transport/storage via dependency injection, eliminate direct transport/storage imports in UI layers, and wire app globally in `main.dart`.

## 🔒 My Identity
- Archetype: implementer
- Roles: implementer, qa, specialist
- Working directory: /home/tommy/messaging/.agents/worker_m4
- Original parent: 52e3c977-b7eb-4874-b1c2-97da36dbba3b
- Milestone: Milestone 4

## 🔒 Key Constraints
- Zero direct `core/storage` or `core/transport` imports in `lib/features/*/presentation/` UI files.
- No hardcoded test results or facade implementations.
- Clean serverless offline keypair identity (Ed25519/X25519) - no Matrix user ID syntax (`@user:server`).
- Dynamic real-time updates via `TransportAdapter` and `LocalStorageRepository`.
- `flutter analyze` 0 errors.
- `flutter test` all tests pass.

## Current Parent
- Conversation ID: 52e3c977-b7eb-4874-b1c2-97da36dbba3b
- Updated: 2026-07-28T00:10:05Z

## Task Summary
- **What to build**:
  1. Auth feature: BLoC + Screen for local offline identity generation/import & Base58 fingerprint / QR code display & import.
  2. Settings feature: `SettingsBloc` / `SettingsCubit` for Relay URL configuration, Tor toggle, key management, panic purge. Decouple UI.
  3. Chat List feature: `ChatListBloc` and `NewChatCubit`. Subscribe to transport stream & local storage. `NewChatModal` Base58 fingerprint + relay URL hint validation.
  4. Chat Room feature: `ChatRoomBloc` for message history, payload encryption/decryption (`E2eCryptoService`), sending & saving envelopes. `MessageStream` BLoC rendering.
  5. App Wiring (`lib/main.dart` & `AppRoutes`): MultiProvider + route generation BLoC providers + startup identity routing.
  6. Architecture boundary check: Zero UI files import `core/storage` or `core/transport`.
  7. Verification: `flutter analyze` (0 errors) & `flutter test` (all pass).
- **Success criteria**: 0 errors on analyze, 100% passing tests, clean architecture boundary.
- **Interface contracts**: `/home/tommy/messaging/.agents/orchestrator/PROJECT.md`
- **Code layout**: Layered architecture: UI -> BLoC -> Domain/Repository interfaces -> Core data implementations.

## Key Decisions Made
- Use BLoC / Cubit for state management across all features.
- Inject dependencies via Provider / BLoC constructors.

## Artifact Index
- `/home/tommy/messaging/.agents/worker_m4/handoff.md` — Final handoff report

## Change Tracker
- **Files modified**: None yet
- **Build status**: Untested
- **Pending issues**: None

## Quality Status
- **Build/test result**: TBD
- **Lint status**: TBD
- **Tests added/modified**: TBD

## Loaded Skills
- None
