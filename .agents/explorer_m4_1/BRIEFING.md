# BRIEFING — 2026-07-28T00:09:00Z

## Mission
Investigate and produce a detailed refactoring plan for Auth/Identity and Settings UI & BLoCs in Milestone 4.

## 🔒 My Identity
- Archetype: Teamwork Explorer
- Roles: Explorer 1 (Milestone 4 - UI Features & BLoCs Integration - Auth & Settings)
- Working directory: /home/tommy/messaging/.agents/explorer_m4_1
- Original parent: 52e3c977-b7eb-4874-b1c2-97da36dbba3b
- Milestone: Milestone 4

## 🔒 Key Constraints
- Read-only investigation — do NOT implement project code changes
- Read-only on source code, write only to working directory `.agents/explorer_m4_1/`

## Current Parent
- Conversation ID: 52e3c977-b7eb-4874-b1c2-97da36dbba3b
- Updated: 2026-07-28T00:09:00Z

## Investigation State
- **Explored paths**:
  - `lib/features/auth/` (`auth_bloc.dart`, `auth_screen.dart`, `auth_text_field.dart`, `custom_server_text_field.dart`)
  - `lib/features/settings/` (`settings_screen.dart`, `key_management_cards.dart`, `panic_button.dart`, `tor_switch_tile.dart`)
  - `lib/core/identity/` (`identity_service.dart`, `local_identity.dart`, `base58.dart`)
  - `lib/core/transport/` (`transport_adapter.dart`, `relay_transport_adapter.dart`)
  - `lib/core/storage/` (`database_service.dart`, `local_storage_repository.dart`)
- **Key findings**:
  - Legacy server login/register and Matrix hints (`https://matrix.org or your homeserver`) in `auth_screen.dart`, `auth_bloc.dart`, `custom_server_text_field.dart` must be removed.
  - Auth must be refactored to offline Ed25519/X25519 keypair generation and QR payload import via `OfflineIdentityService`.
  - Settings screen requires Relay Server URL input field linked to `RelayTransportAdapter` and real-time connection status monitoring (`TransportConnectionState`).
  - Presentation widgets and BLoCs currently have direct `core/storage` imports which must be eliminated in favor of clean architecture boundaries.
- **Unexplored areas**: None for Milestone 4 Auth & Settings scope.

## Key Decisions Made
- Formulated comprehensive refactoring specification in `handoff.md`.

## Artifact Index
- `/home/tommy/messaging/.agents/explorer_m4_1/ORIGINAL_REQUEST.md` — Original request log
- `/home/tommy/messaging/.agents/explorer_m4_1/BRIEFING.md` — Working context briefing index
- `/home/tommy/messaging/.agents/explorer_m4_1/handoff.md` — 5-Component Handoff Report & Detailed Refactoring Plan
