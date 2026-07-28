# Core Domain Challenger 2 (Boundary & Concurrency Verifier) — Handoff Report

## 1. Observation

### Test Execution Command & Output
- Command executed: `flutter test test/core/messaging/boundary_concurrency_test.dart test/core/messaging/messaging_test.dart`
- Results: **17 passed, 0 failed** in core messaging suite.

### Target Files Inspected
1. `lib/core/messaging/message_envelope.dart`
   - Lines 25: `final List<int> payload;`
   - Lines 57-66: `toJson()` returns `'payload': payload`
   - Lines 121-131: `operator ==` uses `listEquals(other.payload, payload)`
   - Lines 134-143: `hashCode` uses `Object.hashAll(payload)`
2. `lib/core/messaging/e2e_crypto_service.dart`
   - Lines 69-92: `_generateKeyStream` loops over SHA-256 blocks, instantiating `blockInput = <int>[...sharedKey, ...nonce, ...]` per 32-byte block.
   - Lines 95-99: `_computeMac` instantiates `macInput = <int>[...nonce, ...encryptedBytes]`.
   - Lines 102-141: `encryptPayload` and `decryptPayload` methods.
3. `lib/core/messaging/conversation.dart`
   - Lines 33-41: `addMessage` calls `List<MessageEnvelope>.from(messages)..add(message)` creating a full copy of `messages` on every message add.
   - Lines 120-126: `hashCode` calls `Object.hashAll(messages)`.

### Empirical Test Findings & Performance Metrics
1. **Large Message Payload (1MB & 5MB Binary Data)**:
   - **1MB Encryption & Decryption**: E2E Encrypt: `465ms`, Decrypt: `263ms` (Total roundtrip: ~`728ms`).
   - **5MB Encryption & Decryption**: E2E Roundtrip: `2,336ms` (~2.3 seconds).
   - **1MB JSON Serialization Amplification**: `MessageEnvelope.toJson()` produces a raw `List<int>` in JSON string (`[0, 1, 2, ...]`). 1,048,576 bytes raw binary payload serializes to `3,743,976 bytes` of JSON text — a **3.57x payload amplification factor**.
   - **1MB JSON Encoding & Decoding Time**: `toJson & jsonEncode`: `149ms`, `jsonDecode & fromJson`: `152ms`.
   - **1MB `hashCode` & Equality Overhead**: `Object.hashAll(payload)` on 1MB byte list takes `37ms` per hash evaluation. `listEquals` takes `7ms` per comparison.

2. **Concurrent Keypair Generation**:
   - **100 & 200 Concurrent Keypair Generations**: Completed in `4ms` total (`0.04ms` per keypair) via `Future.wait` on `OfflineIdentityService`.
   - **Fingerprint & Key Uniqueness**: 200/200 generated identities possessed 100% unique public keys, secret keys, and Base58 fingerprints (`0` collisions).

3. **Multi-Message Envelope Updates & Conversation Scaling**:
   - **Sequential `addMessage` Scaling**: Adding 2,000 messages sequentially took `36ms`. `Conversation.toJson()` with 2,000 messages took `20ms`. `Conversation.hashCode` with 2,000 messages took `8ms`.
   - **Concurrency behavior**: In single-isolate Dart event loop, immutable `Conversation` state updates inside single event cycles run sequentially. However, unsynchronized asynchronous state stores risk losing message envelope updates if state references are modified concurrently across async gaps without atomic state transitions.

---

## 2. Logic Chain

1. **Observation**: `MessageEnvelope.toJson()` serializes `payload` as a Dart `List<int>`, which standard `jsonEncode` renders as an ASCII integer list `[10, 20, 30, ...]`.
   - **Logic**: Each byte (0-255) requires 1 to 3 digits plus a comma separator (e.g. `255,`). For a 1MB payload (1,048,576 bytes), this produces ~3.74MB of JSON text (3.57x expansion).
   - **Inference**: Transporting or persisting large binary payloads (images/files) via standard `MessageEnvelope.toJson()` will bloat network and disk I/O significantly compared to Base64 encoding (1.33x expansion) or direct binary buffers.

2. **Observation**: `PlaceholderE2eCryptoService._generateKeyStream` creates a temporary `<int>[...sharedKey, ...nonce, ...]` list for every 32-byte block, and `_computeMac` creates `<int>[...nonce, ...encryptedBytes]`.
   - **Logic**: For a 5MB payload, `_generateKeyStream` executes 163,840 block iterations, allocating 163,840 intermediate `List<int>` instances. Furthermore, `...encryptedBytes` allocates a 5MB array copy.
   - **Inference**: High allocation rates during large payload encryption/decryption cause substantial GC pressure and slow down operations (~2.3s for 5MB).

3. **Observation**: `MessageEnvelope.hashCode` invokes `Object.hashAll(payload)`.
   - **Logic**: `Object.hashAll` iterates through all 1,048,576 integer elements in `payload`.
   - **Inference**: Placing 1MB `MessageEnvelope` instances in hash-based collections (`Set`, `Map`) or calculating equality repeatedly creates non-trivial CPU stalls (~37ms per hash call).

4. **Observation**: `OfflineIdentityService.generateIdentity` uses `Random.secure()` and deterministic SHA-256 key derivation.
   - **Logic**: In tests with 200 concurrent keypair generation calls, 200 distinct identities were produced without any key collisions or race condition errors.
   - **Inference**: `OfflineIdentityService` is robust and safe for concurrent keypair generation calls.

---

## 3. Caveats

- **Isolate Thread Boundaries**: The empirical concurrency tests ran within a single Dart isolate event loop. Multi-isolate (parallel thread) access to shared `Conversation` state was not tested as Dart isolates do not share mutable memory by default.
- **Placeholder Crypto Service Scope**: `PlaceholderE2eCryptoService` is designed as a clean placeholder implementation (SHA-256 XOR stream). Production crypto will likely use libsodium / WebCrypto / Rust FFI implementations.

---

## 4. Conclusion

- **Boundary Assessment**: `MessageEnvelope` and `PlaceholderE2eCryptoService` correctly process 1MB+ binary payloads without crashing or corrupting data. However, performance degradation and a **3.57x payload memory amplification** occur during JSON serialization, along with high GC allocation overhead during encryption of payloads >1MB.
- **Concurrency Assessment**: `OfflineIdentityService` keypair generation handles high-concurrency loads flawlessly with 0 collisions across 200 concurrent operations. `Conversation` immutable updates are clean, but state holders must ensure atomic state mutation when handling concurrent incoming envelopes.

---

## 5. Verification Method

To independently verify these empirical results, execute:

```bash
flutter test test/core/messaging/boundary_concurrency_test.dart
```

### Expected Output
- All 8 boundary and concurrency stress tests pass.
- Log outputs verify metric logs for 1MB E2E payload roundtrip (~465ms enc, ~263ms dec), JSON amplification factor (~3.57x), and 200 concurrent keypair generations with 0 collisions.
