## 2026-07-27T19:11:49Z
Your working directory is /home/tommy/messaging/.agents/teamwork_preview_worker_m1_1.
Your role: Core Domain Layer Implementer.

Objective:
Implement pure Dart domain models, services, and interfaces for Milestone 1 in /home/tommy/messaging/lib/core/:

1. `lib/core/identity/local_identity.dart` & `lib/core/identity/identity_service.dart`:
   - `LocalIdentity`: `publicKey`, `secretKey`, `fingerprint` (Base58/Base64 public key fingerprint), `displayName`, `createdAt`.
   - `IdentityService`: Keypair generation interface and offline implementation (using Dart `crypto` / Ed25519 or random seed generation + Base58/Base64 encoding), QR export (`exportToQr`), QR import (`importFromQr`).
   - Zero registration on any external server required to generate an identity.
   - NO Matrix user ID format (`@user:server` syntax).

2. `lib/core/addressing/contact_address.dart`:
   - `ContactAddress`: `fingerprint`, `displayName`, `relayUrlHint`.
   - Parsing, validation (valid fingerprint regex/checks), JSON serialization.

3. `lib/core/messaging/message_envelope.dart`, `lib/core/messaging/conversation.dart`, `lib/core/messaging/e2e_crypto_service.dart`:
   - `MessageDeliveryStatus` enum: `pending`, `sent`, `delivered`, `failed`.
   - `MessageEnvelope`: `id`, `senderFingerprint`, `recipientFingerprint`, `payload` (`List<int>`), `timestamp`, `status`.
   - `Conversation`: `id`, `contact` (`ContactAddress`), `messages` (`List<MessageEnvelope>`), `unreadCount`, `lastUpdated`.
   - `E2eCryptoService`: Abstract interface + placeholder/stub implementation (`PlaceholderE2eCryptoService`) that simulates E2E payload wrapping/unwrapping cleanly.

4. Layer documentation:
   - Add a clean barrel file or README (`README.md` or `identity.dart`, `addressing.dart`, `messaging.dart`) in each folder (`lib/core/identity/`, `lib/core/addressing/`, `lib/core/messaging/`) explaining layer responsibility.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

When completed:
- Run `dart analyze` or `flutter analyze` or verification checks if possible and record results in handoff.
- Write report to /home/tommy/messaging/.agents/teamwork_preview_worker_m1_1/handoff.md and message orchestrator.
