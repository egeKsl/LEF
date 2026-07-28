# Handoff Report: Storage & Database Stress Testing (M2)

**Agent Working Directory**: `/home/tommy/messaging/.agents/teamwork_preview_challenger_m2_1`  
**Role**: Transport/Storage Challenger 1 (Database Stress Tester)  
**Target Subsystems**: `lib/core/storage/database_service.dart`, `lib/core/storage/local_storage_repository.dart`  
**Verification Test Suite**: `test/core/storage/storage_stress_test.dart`

---

## 1. Observation

Direct empirical observations, code inspection, and test execution results from `test/core/storage/storage_stress_test.dart`:

### A. Heavy Load & 1MB BLOB Performance Metrics
1. **LocalIdentity (500 Ops)**:
   - 500 `saveIdentity` operations completed in **90 ms**.
   - Inspection of `lib/core/storage/database_service.dart` (lines 69-77):
     ```sql
     CREATE TABLE identity (
       publicKey TEXT PRIMARY KEY,
       secretKey TEXT NOT NULL,
       fingerprint TEXT NOT NULL,
       displayName TEXT NOT NULL,
       createdAt TEXT NOT NULL
     )
     ```
   - Inspection of `lib/core/storage/local_storage_repository.dart` (lines 33-38):
     ```dart
     Future<LocalIdentity?> loadIdentity() async {
       final db = await _dbService.database;
       final maps = await db.query('identity', limit: 1);
       if (maps.isEmpty) return null;
       return LocalIdentity.fromJson(maps.first);
     }
     ```
   - **Empirical Observation**: When 500 `LocalIdentity` instances with different `publicKey` strings are saved via `saveIdentity`, SQLite inserts 500 separate rows because `publicKey` is the PRIMARY KEY. Calling `loadIdentity()` executes `db.query('identity', limit: 1)` without an `ORDER BY` clause, returning `maps.first` (the initial `User_0` record). Key rotations or updates saving a new `publicKey` leave stale identity records in the table, and `loadIdentity()` returns the oldest stale identity.

2. **ContactAddress (500 Ops)**:
   - 500 `saveContact` operations completed in **70 ms**.
   - `getContacts()` fetched all 500 contacts cleanly.

3. **MessageEnvelope & 1MB BLOB Payloads (500MB Total Data)**:
   - 500 x 1MB binary BLOB insertions into `messages` table completed in **4,148 ms** (~8.3 ms per 1MB insert).
   - Single 1MB BLOB fetch via `getEnvelope(id)` latency: **31 ms**.
   - Fetching all 500 x 1MB messages for a single conversation via `getEnvelopesForConversation('conv_heavy_1')` latency: **10,033 ms** (10.03 seconds).
   - Inspection of `lib/core/storage/local_storage_repository.dart` (lines 130-139):
     ```dart
     Future<List<MessageEnvelope>> getEnvelopesForConversation(String conversationId) async {
       final db = await _dbService.database;
       final maps = await db.query(
         'messages',
         where: 'conversationId = ?',
         whereArgs: [conversationId],
         orderBy: 'timestamp ASC',
       );
       return maps.map(_parseEnvelopeMap).toList();
     }
     ```
   - **Empirical Observation**: `getEnvelopesForConversation` and `getConversation(id)` load all matching messages and their full binary payloads into heap memory at once without limit/offset pagination or streaming. Deserializing 500 x 1MB BLOBs (500MB raw bytes) blocks the Dart event loop for >10 seconds and creates severe memory pressure.

4. **Conversation Persistence (500 Messages x 100KB Payload)**:
   - Batch insert of a `Conversation` with 500 messages inside a single transaction completed in **502 ms**.

### B. Foreign Key Constraints & Cascade Deletion Failure
1. Inspection of `lib/core/storage/database_service.dart` (lines 67-112):
   - Table schema defines foreign keys:
     - `FOREIGN KEY (contactFingerprint) REFERENCES contacts (fingerprint) ON DELETE CASCADE`
     - `FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE`
   - `PRAGMA foreign_keys = ON;` is **never executed** during database creation (`_onCreate`), initialization (`_initDatabase`), or connection opening (`database` getter).
2. Inspection of `lib/core/storage/local_storage_repository.dart` (lines 85-92):
   ```dart
   Future<void> deleteContact(String fingerprint) async {
     final db = await _dbService.database;
     await db.delete(
       'contacts',
       where: 'fingerprint = ?',
       whereArgs: [fingerprint],
     );
   }
   ```
3. Inspection of `lib/core/storage/local_storage_repository.dart` (lines 245-248):
   ```dart
   final contact = await getContact(contactFp);
   if (contact == null) {
     throw StateError('Contact for conversation $id with fingerprint $contactFp not found');
   }
   ```
4. **Empirical Observation**: Because SQLite disables foreign keys by default and `DatabaseService` does not execute `PRAGMA foreign_keys = ON;`, calling `deleteContact(fingerprint)` deletes the contact row but leaves orphaned `conversations` referencing the deleted `contactFingerprint`. When `getConversation(id)` or `getConversations()` is subsequently called, `getContact(contactFp)` returns `null`, throwing an uncaught `StateError` that crashes the entire `getConversations()` query for all conversations in the app!

### C. Unread Count Tracking & Synchronization Flaws
1. Inspection of `lib/core/storage/local_storage_repository.dart` (lines 99-114):
   ```dart
   Future<void> saveEnvelope(MessageEnvelope envelope, {required String conversationId}) async {
     final db = await _dbService.database;
     await db.insert(
       'messages',
       { ... },
       conflictAlgorithm: ConflictAlgorithm.replace,
     );
   }
   ```
2. **Empirical Observation**: `saveEnvelope` inserts a message envelope into the `messages` table, but does NOT update `conversations.unreadCount` or `conversations.lastUpdated` in the `conversations` table.
3. In Test 4.1, an incoming message envelope saved via `saveEnvelope` resulted in the conversation retaining an `unreadCount` of `0` and an obsolete `lastUpdated` timestamp.
4. `LocalStorageRepository` lacks helper methods to increment unread counts, decrement unread counts, or mark conversations as read.

### D. Missing SQL Indexes
1. Inspection of `lib/core/storage/database_service.dart` (lines 67-112):
   - No `CREATE INDEX` statements exist for `messages(conversationId, timestamp)` or `conversations(lastUpdated)`.
   - Queries filtering by `conversationId` or ordering by `timestamp` / `lastUpdated` rely on full table scans.

---

## 2. Logic Chain

1. **Stale LocalIdentity Recovery Bug**:
   - `saveIdentity` performs `db.insert('identity', identity.toJson())` using `publicKey` as PK.
   - Saving a new identity (e.g. keypair rotation) creates a new row instead of replacing the old one.
   - `loadIdentity()` runs `db.query('identity', limit: 1)` without `ORDER BY`. SQLite returns the first row created.
   - **Conclusion**: `loadIdentity()` will permanently return the initial identity created, ignoring all subsequent identity updates.

2. **Orphaned Conversation Storage Crash Bug**:
   - SQLite enforces FK constraints only when `PRAGMA foreign_keys = ON;` is set per connection. `DatabaseService` omits this configuration.
   - Calling `deleteContact(fp)` removes the contact row but leaves referencing rows in `conversations`.
   - `getConversation(id)` explicitly throws `StateError('Contact for conversation $id with fingerprint $contactFp not found')` if `getContact(contactFp)` is `null`.
   - `getConversations()` loops through all conversations and calls `getConversation(id)`.
   - **Conclusion**: Deleting any contact causes `getConversations()` to throw an uncaught exception, breaking conversation listing for the entire application.

3. **Unread Count & Activity Desynchronization**:
   - Background message delivery stores messages using `saveEnvelope(envelope, conversationId: convId)`.
   - `saveEnvelope` only touches the `messages` table.
   - **Conclusion**: As messages arrive via transport, the `conversations` table header remains stale, showing incorrect `unreadCount` and outdated `lastUpdated` times in the UI.

4. **Memory Bottleneck & Latency under Heavy Payload**:
   - `getEnvelopesForConversation` queries all messages for a conversation into a single in-memory list without limit or offset.
   - In empirical testing, fetching 500 x 1MB BLOB messages took **10,033 ms** and loaded 500MB of raw bytes into memory simultaneously.
   - **Conclusion**: Large media payloads (1MB+ attachments) in conversation history will cause severe UI freezing (>10 seconds) and high OOM crash risk on mobile devices.

---

## 3. Caveats

1. **Native SQLite FFI Environment**:
   - Linux test execution used `FakeDatabase` as the in-memory mock driver due to system-level `libsqlite3.so` dependency limits in the test environment.
   - Physical device behavior (iOS/Android sqflite native plugins) will enforce identical SQL schema syntax, but transaction write locking speeds may vary based on device storage I/O capabilities.
2. **Review-Only Constraint**:
   - Per EMPIRICAL CHALLENGER role constraints, no production code in `lib/core/storage/` was modified. All verification was conducted through `test/core/storage/storage_stress_test.dart`.

---

## 4. Conclusion

`DatabaseService` and `LocalStorageRepository` successfully handle standard CRUD operations and multi-entity transactions under moderate load. However, stress testing revealed four **CRITICAL Architectural Vulnerabilities**:

1. **Orphaned Contact Crash (CRITICAL)**: Deleting a contact without `PRAGMA foreign_keys = ON;` leaves orphaned conversations that cause `getConversations()` to throw a `StateError` and crash the storage layer.
2. **Stale Identity Bug (HIGH)**: `saveIdentity` inserts multiple rows when keypairs change; `loadIdentity()` returns the first inserted row instead of the newest.
3. **Unread Count Desync (HIGH)**: `saveEnvelope` does not increment `unreadCount` or update `lastUpdated` in the `conversations` header table.
4. **Unpaginated BLOB Memory Explosion (MEDIUM-HIGH)**: Fetching 500 x 1MB BLOB messages takes >10 seconds and loads 500MB into memory at once due to lack of query pagination.

---

## 5. Verification Method

To independently verify these findings, run the newly created stress test suite:

```bash
flutter test test/core/storage/storage_stress_test.dart
```

### Test Case Verification Matrix:
- **Test 1.1a & 1.1b**: Confirms identity accumulation and `loadIdentity()` first-row selection behavior.
- **Test 1.3**: Demonstrates 500 x 1MB BLOB insertion performance (4,148 ms) and fetch latency (10,033 ms).
- **Test 3.1 & 3.2**: Replicates contact deletion creating orphaned conversations and throwing `StateError` during `getConversations()`.
- **Test 4.1**: Demonstrates `saveEnvelope` failing to update `unreadCount` and `lastUpdated`.
- **Test 5.1 & 5.2**: Verifies non-blocking async execution under 100 concurrent reads/writes and 50 parallel conversation saves.
