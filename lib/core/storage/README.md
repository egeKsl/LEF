# Core Storage Layer

## Overview
The `storage` package provides local SQLite persistence for identities, contacts, conversations, and transport envelopes using `sqflite`.

## Key Components
- **`DatabaseService`**: Manages the local SQLite database lifecycle, path resolution, table schema creation (`identity`, `contacts`, `conversations`, `messages`), and connection teardown.
- **`LocalStorageRepository`**: Provides clean, high-level methods for storing, querying, updating, and deleting domain models:
  - `LocalIdentity`: `saveIdentity()`, `loadIdentity()`, `deleteIdentity()`
  - `ContactAddress`: `saveContact()`, `getContact()`, `getContacts()`, `deleteContact()`
  - `Conversation`: `saveConversation()`, `getConversation()`, `getConversations()`, `deleteConversation()`
  - `MessageEnvelope`: `saveEnvelope()`, `getEnvelope()`, `getEnvelopesForConversation()`, `getAllEnvelopes()`, `deleteEnvelope()`

## Schema & Tables
- **`identity`**: Stores `publicKey`, `secretKey`, `fingerprint`, `displayName`, `createdAt`.
- **`contacts`**: Stores `fingerprint`, `displayName`, `relayUrlHint`.
- **`conversations`**: Stores `id`, `contactFingerprint`, `unreadCount`, `lastUpdated`.
- **`messages`**: Stores `id`, `conversationId`, `senderFingerprint`, `recipientFingerprint`, `payload` (BLOB), `timestamp`, `status`.

## Constraints & Architectural Rules
1. **Local-Only Storage**: Persistent storage stays strictly on-device; no cloud or server sync in storage layer.
2. **Matrix Prohibited**: Matrix user ID formats (`@user:server` syntax) are strictly prohibited across all models and DB columns.
3. **Cascading Deletions**: Deleting a conversation automatically cascades to delete all associated messages.
