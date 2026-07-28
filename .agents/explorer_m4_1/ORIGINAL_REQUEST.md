## 2026-07-27T20:58:53Z
You are Explorer 1 for Milestone 4 (UI Features & BLoCs Integration - Auth & Settings).
Your working directory is /home/tommy/messaging/.agents/explorer_m4_1.

Objectives:
1. Examine all files in `lib/features/auth/` (and any related auth/identity screens or BLoCs) and `lib/features/settings/`.
2. Map out how `AuthBloc` / `AuthScreen` (or `IdentityBloc` / `IdentityScreen`) should be refactored to:
   - Handle offline Ed25519/X25519 keypair generation and import via `OfflineIdentityService` (`lib/core/identity/offline_identity_service.dart`).
   - Present local keypair public key fingerprint (Base58/Base64), QR code generation/display, and QR code import options.
   - Completely remove any remaining references to login/register against central servers or Matrix homeservers.
3. Map out how `SettingsScreen` (in `lib/features/settings/`) should be refactored to:
   - Provide a Relay Server URL text input field linked to `RelayTransportAdapter` configuration.
   - Display the active relay URL and real-time connection status (`disconnected`, `connecting`, `connected`, `error`).
4. Ensure no direct imports of `lib/core/transport/` or `lib/core/storage/` exist in UI widgets (UI depends only on domain services / BLoC interfaces).

Deliver your detailed refactoring plan and code analysis in `/home/tommy/messaging/.agents/explorer_m4_1/handoff.md`.
