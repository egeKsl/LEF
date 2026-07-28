# Core Identity Layer

## Overview
The `identity` package provides client-side, serverless identity primitives for the messaging system.

## Key Components
- **`LocalIdentity`**: Domain model representing a local cryptographic keypair (`publicKey`, `secretKey`), Base58 public key fingerprint, human-readable `displayName`, and creation timestamp `createdAt`.
- **`IdentityService`**: Abstract contract for offline keypair generation, QR code export (`exportToQr`), and QR code import (`importFromQr`).
- **`OfflineIdentityService`**: Offline implementation using secure random generation, SHA-256 seed derivation, and Base58 fingerprint calculation without external server dependencies.
- **`Base58`**: Pure Dart Base58 encoding and decoding utility.

## Constraints & Architectural Rules
1. **Serverless Identity**: Identity generation requires zero registration on external servers or central authorities.
2. **Disallowed Formats**: Matrix user ID formats (`@user:server` syntax) are strictly prohibited across all identity models and validators.
