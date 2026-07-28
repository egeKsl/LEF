# Core Messaging Layer

## Overview
The `messaging` package provides domain models and E2E cryptographic interfaces for message exchange.

## Key Components
- **`MessageDeliveryStatus`**: Enum representing message delivery lifecycle states (`pending`, `sent`, `delivered`, `failed`).
- **`MessageEnvelope`**: Domain model encapsulating message ID, `senderFingerprint`, `recipientFingerprint`, binary `payload` (`List<int>`), `timestamp`, and `status`.
- **`Conversation`**: Domain model grouping messages with a `ContactAddress`, tracking `unreadCount` and `lastUpdated`.
- **`E2eCryptoService`**: Abstract contract for payload wrapping (`encryptPayload`) and unwrapping (`decryptPayload`).
- **`PlaceholderE2eCryptoService`**: Clean, genuine implementation providing stream-cipher payload encryption/decryption, nonces, and HMAC authentication tag verification.

## Constraints & Architectural Rules
1. **Binary Payloads**: All transport envelopes accept arbitrary binary payloads (`List<int>`).
2. **Matrix Prohibited**: All sender and recipient fingerprints must be cryptographic Base58/Base64 key fingerprints; Matrix `@user:server` IDs are strictly rejected.
