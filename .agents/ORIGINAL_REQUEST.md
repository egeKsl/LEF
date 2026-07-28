# Original User Request

## Initial Request — 2026-07-27T21:59:49Z

<USER_REQUEST>
Rebuild the Flutter messaging application at `/home/tommy/messaging` from a tangled Matrix+P2P experiment into a clean, SimpleX-inspired layered architecture. The app must work globally (no LAN assumptions), be transport-agnostic (relay-first, Tor-ready later), and have zero dead code paths in production flows.

Working directory: /home/tommy/messaging

---

## Current State (Before)

The existing codebase has severe architectural debt:

| Problem | File(s) |
|---------|---------|
| LAN-only P2P HTTP server on port 8008 | `lib/core/p2p/p2p_node_service.dart` |
| Mock data hardcoded in production path | `lib/features/chat/data/mock_chat_data.dart`, `lib/features/chat_room/data/mock_chat_room_messages.dart` |
| Inverted bool flag routes live traffic to mocks | `chat_list_screen.dart` (`kDisableMocksForProduction = false` sends to Matrix, not mock) |
| P2P singleton wired into auth, chat room, new chat modal | `auth_bloc.dart`, `chat_room_screen.dart`, `new_chat_modal.dart` |
| Yggdrasil/loopback/127.0.0.1 references in strings | `p2p_node_service.dart`, mock data rooms |
| Matrix SDK used as identity+transport hybrid | `matrix_auth_service.dart` |
| No separation between identity, addressing, messaging protocol, transport | entire codebase |

---

## Requirements

### R1. Clean Layered Architecture
Reorganize `lib/` into these layers with strict dependency rules (UI → domain → data, no reverse):
- `lib/core/identity/` — local keypair generation, no central server dependency
- `lib/core/addressing/` — contact address model, relay address, abstract transport address
- `lib/core/messaging/` — message model, E2E encryption interface, delivery receipt, queue/retry/ack
- `lib/core/transport/` — abstract `TransportAdapter` interface + one concrete `RelayTransportAdapter`
- `lib/core/storage/` — encrypted local SQLite storage, offline queue, conversation state
- `lib/features/` — UI features that only talk to domain layer, never directly to transport/storage

### R2. Remove All Legacy Dead Paths
Delete or fully replace these files/patterns — none may remain in any production code path:
- `lib/core/p2p/p2p_node_service.dart` (delete)
- `lib/features/chat/data/mock_chat_data.dart` (delete)
- `lib/features/chat_room/data/mock_chat_room_messages.dart` (delete)
- All `MockChatPreview`, `MockMessage`, `kUseMockChatPreview`, `kDisableMocksForProduction` references
- All `P2pNodeService`, `P2pPeer`, `P2pMessage` references
- All `yggdrasil`, `127.0.0.1`, loopback, LAN-IP string literals in production paths
- `_isServerlessPeerTarget`, `_buildP2pPreview` functions in `new_chat_modal.dart`
- All `matrix` package imports (`package:matrix/...`) from every file
- `matrix_auth_service.dart` (delete)
- `MatrixAuthService`, `matrix.Client`, `matrix.Room`, `matrix.Timeline`, `matrix.SyncUpdate` references everywhere

### R3. Identity Layer (No Central Server Required)
Implement a local device identity system:
- Generate a keypair (Ed25519 or X25519) on first launch, stored encrypted locally
- Identity is represented as a base58/base64 public key fingerprint — no Matrix user ID format, no `@user:server` syntax
- No registration on any external server required to generate an identity
- Export/import identity as a QR code or text blob
- Matrix login/register flow must be **completely removed** — delete `matrix_auth_service.dart`, the Matrix SDK dependency from `pubspec.yaml`, and all Matrix-related BLoC events/states
- Remove the `matrix` package from `pubspec.yaml` and all its imports

### R4. Transport-Agnostic Messaging Protocol
Define an abstract `TransportAdapter` with at minimum:
```dart
abstract class TransportAdapter {
  Future<void> connect();
  Future<void> disconnect();
  Future<bool> sendEnvelope(MessageEnvelope envelope);
  Stream<MessageEnvelope> get incomingEnvelopes;
}
```
Implement one concrete adapter: `RelayTransportAdapter` that connects to a configurable relay server URL (WebSocket or HTTP long-poll). The relay URL must be configurable in settings, not hardcoded. Tor transport must be architecturally possible by adding a second adapter later without touching the protocol layer.

### R5. Messaging Protocol Layer
Define clean domain models:
- `LocalIdentity` — keypair, fingerprint, display name
- `ContactAddress` — another party's public key fingerprint + optional relay hint
- `MessageEnvelope` — encrypted payload, sender fingerprint, recipient fingerprint, timestamp, message ID, delivery status (pending/sent/delivered/failed)
- `Conversation` — list of envelopes, contact info, unread count
Implement stub E2E encryption (interface + placeholder implementation) so the structure is correct even if full crypto is not complete in this phase.

### R6. UI Layer Decoupled from Transport
UI screens must:
- Receive data only through BLoC/Cubit or Repository interfaces
- Never import from `core/transport/` or `core/storage/` directly
- The chat list must show real conversations from local storage (not mock data)
- The chat room must show real messages from local storage and send via the messaging layer
- The "New Chat" modal must use the new addressing model (contact address / public key), removing the IP-input fallback

### R7. Settings Screen — Relay Configuration
Add a relay server URL configuration field to the existing settings screen. The current relay URL and connection status must be visible. No hardcoded relay URLs.

### R8. F-Droid & Privacy Compliance
- All dependencies must be open-source and available on pub.dev
- No Firebase, no Google Analytics, no crash reporting SDKs
- No new permissions beyond what is already declared (`camera`, `storage`)
- `pointycastle` or `cryptography` package for crypto primitives (both are F-Droid safe)

---

## Acceptance Criteria

### Architecture
- [ ] No file in `lib/features/` imports from `lib/core/transport/` or `lib/core/storage/` directly
- [ ] `lib/core/p2p/` directory does not exist
- [ ] No `MockChatPreview`, `MockMessage`, `kUseMockChatPreview`, `kDisableMocksForProduction` identifiers exist in any `.dart` file
- [ ] No `P2pNodeService`, `P2pPeer`, `P2pMessage` identifiers exist in any `.dart` file
- [ ] No string literals containing `yggdrasil`, `127.0.0.1`, `loopback`, `8008` exist in production `.dart` files
- [ ] `TransportAdapter` is an abstract class; `RelayTransportAdapter` implements it

### Build
- [ ] `flutter analyze` produces zero errors (warnings acceptable)
- [ ] `flutter build apk --debug` succeeds without errors

### Functionality
- [ ] App launches without crash on first run
- [ ] On first launch with no saved identity, user is prompted to create or import a local identity
- [ ] After identity creation, the chat list screen is shown (empty but functional, no mock data)
- [ ] Tapping the new chat FAB opens a modal that accepts a contact address (public key fingerprint), not an IP address
- [ ] Settings screen has a relay URL input field
- [ ] No `package:matrix/` import exists in any `.dart` file
- [ ] `matrix` package does not appear in `pubspec.yaml` dependencies

### Code Quality
- [ ] Each layer folder has a clear README comment or barrel file explaining its responsibility
- [ ] No commented-out dead code blocks remain
- [ ] File names follow `snake_case.dart` convention throughout
</USER_REQUEST>
