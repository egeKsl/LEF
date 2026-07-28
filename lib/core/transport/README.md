# Core Transport Layer

## Overview
The `transport` package provides abstract interfaces and concrete implementations for envelope transmission and network communication with relay servers.

## Key Components
- **`TransportConnectionState`**: Enum representing transport lifecycle states (`disconnected`, `connecting`, `connected`, `disconnecting`, `error`).
- **`TransportAdapter`**: Abstract contract defining `connect()`, `disconnect()`, `sendEnvelope(MessageEnvelope)`, `incomingEnvelopes` stream, and `connectionState` stream.
- **`RelayTransportAdapter`**: Concrete implementation supporting configurable relay URLs, asynchronous connection management, stream-based envelope reception, and simulation tools for push/receive testing.

## Constraints & Architectural Rules
1. **Configurable Relay URL**: Relay endpoints must be configurable (`relayUrl` parameter) with zero hardcoded URLs.
2. **Matrix Prohibited**: Matrix `@user:server` ID formats are strictly prohibited in relay URLs and message envelope fingerprints.
3. **Binary Envelopes**: All network payloads travel wrapped inside `MessageEnvelope` binary payloads.
