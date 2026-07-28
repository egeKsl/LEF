# Core Addressing Layer

## Overview
The `addressing` package manages peer identity addressing and relay hint information for decentralized messaging.

## Key Components
- **`ContactAddress`**: Domain model representing a peer contact, containing their Base58/Base64 `fingerprint`, `displayName`, and optional `relayUrlHint`.
- **Validation**: Includes strict fingerprint validation (`isValidFingerprint`) and string parsing (`ContactAddress.parse`).

## Constraints & Architectural Rules
1. **Matrix Syntax Prohibited**: Matrix user ID syntax (`@user:server`) is strictly forbidden. Fingerprints must be cryptographic public key fingerprints.
2. **Relay URL Hints**: Optional hint URIs for optional relay/transport servers without central registration requirement.
