# Empirical Challenge Report: Core Domain Models & Cryptography

**Agent Role**: Core Domain Challenger 1 (Property-Based Tester)  
**Target Directory**: `/home/tommy/messaging/lib/core/`  
**Test Harness Created**: `/home/tommy/messaging/test/core/domain_crypto_property_test.dart`  
**Execution Date**: 2026-07-27  

---

## 1. Observation

### Test Execution Command & Summary
- **Command Executed**:
  ```bash
  flutter test test/core/domain_crypto_property_test.dart
  ```
- **Test Output Summary**:
  ```text
  00:00 +0: ... /home/tommy/messaging/test/core/domain_crypto_property_test.dart
  00:03 +1: Property-Based ... with random byte arrays including leading zeros
  00:03 +2: Property-Based ... throws FormatException on invalid characters
  00:03 +3: Property-Based ... keypairs and verify cryptographic invariants
  00:03 +4: Property-Based ... and import round-trips with random identities
  00:03 +5: Property-Based ... QR Payload Tampering & Lack of Checksum/Signature
  00:04 +6: Property-Based ... with random byte arrays of varying sizes
  00:04 +7: ... MAC tag, or Ciphertext payload triggers Authentication Exception
  00:04 +8: Property-Based ... Ciphertext truncation safety checks (<32 bytes)
  00:04 +9: ... of MessageEnvelope, ContactAddress, and Conversation round-trips
  All tests passed!
  ```

### Target Source Code Observations

1. **`lib/core/identity/identity_service.dart` (Lines 72-120)**:
   ```dart
   @override
   String exportToQr(LocalIdentity identity) {
     final jsonMap = identity.toJson();
     final jsonString = jsonEncode(jsonMap);
     return base64Url.encode(utf8.encode(jsonString));
   }

   @override
   LocalIdentity importFromQr(String qrData) {
     ...
     final identity = LocalIdentity.fromJson(jsonMap);
     try {
       final pubKeyBytes = Base58.decode(identity.publicKey);
       final expectedFingerprint = Base58.encode(sha256.convert(pubKeyBytes).bytes);
       if (identity.fingerprint != expectedFingerprint) {
         throw const FormatException('Identity fingerprint mismatch with public key');
       }
     } catch (e) {
       ...
     }
     return identity;
   }
   ```

2. **`lib/core/messaging/e2e_crypto_service.dart` (Lines 101-187)**:
   - Encrypts payload into a 32-byte header envelope format: `[16 bytes Nonce] + [16 bytes HMAC-SHA256 MAC tag] + [Encrypted XOR stream]`.
   - `decryptPayload` verifies MAC tag on lines 168-177:
     ```dart
     for (int i = 0; i < 16; i++) {
       if (expectedMac[i] != computedMac[i]) {
         throw const FormatException(
           'E2E Payload MAC authentication failed: invalid key or tampered ciphertext',
         );
       }
     }
     ```

3. **`lib/core/identity/base58.dart` (Lines 20-99)**:
   - Pure Dart Base58 codec implementation using Bitcoin Base58 alphabet (`123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz`).

---

## 2. Logic Chain

### A. E2E Payload Encryption & Tamper Detection Correctness
1. **Property Tested**: For 150 random pairs of identities and random byte arrays ranging from 0 B to 64 KB, `decryptPayload(encryptPayload(plaintext)) == plaintext`.
2. **Observation**: 150 iterations completed without a single payload mismatch. Both unidirectional and bidirectional payload exchanges succeeded.
3. **Tamper Property Tested**: Mutating 1 byte in Nonce (bytes 0..15), HMAC tag (bytes 16..31), or Ciphertext payload (bytes 32..end) causes `decryptPayload` to evaluate `expectedMac[i] != computedMac[i]`.
4. **Observation**: In all 150 iterations, mutating any single byte in Nonce, HMAC MAC tag, or Ciphertext payload resulted in `FormatException('E2E Payload MAC authentication failed: invalid key or tampered ciphertext')`.
5. **Key Security Checks**: Decrypting with an altered `senderPublicKey` or altered `recipientSecretKey` alters the derived symmetric shared key (`_deriveSharedKey`), which computes a completely different HMAC tag and fails authentication as expected. Truncating ciphertext below 32 bytes throws `FormatException('Ciphertext is too short...')`.

### B. Base58 & Keypair Invariants
1. **Property Tested**: Generating 150 `LocalIdentity` instances using `OfflineIdentityService`.
2. **Observation**:
   - Every generated `publicKey` decodes to exactly 32 bytes via `Base58.decode`.
   - Every generated `secretKey` decodes to 64 bytes (`32-byte pubKey + 32-byte entropy seed`).
   - Every generated `fingerprint` matches `Base58.encode(sha256(pubKeyBytes))`.
   - Zero collisions occurred across 150 iterations for public keys, secret keys, or fingerprints.
   - Base58 encode/decode round-trips with leading zero byte arrays (e.g., `[0, 0, 1, 2, 3]`) preserved leading zero counts (`'11...'`) correctly.

### C. Security Finding: Stealth QR Payload Tampering Vulnerability
1. **Observation**: `exportToQr` serializes `LocalIdentity.toJson()` into base64Url string. There is no signature or HMAC tag computed over the exported payload.
2. **Observation**: `importFromQr` only verifies `fingerprint == Base58.encode(sha256(pubKeyBytes))`.
3. **Reasoning**: An attacker in the QR transmission path can modify `displayName` or `secretKey` inside the Base64 JSON payload without modifying `publicKey` or `fingerprint`.
4. **Empirical Proof**:
   ```dart
   final original = await identityService.generateIdentity(displayName: 'Alice_Original');
   final jsonMapTamperedName = original.toJson();
   jsonMapTamperedName['displayName'] = 'Mallory_Spoofed';
   final tamperedQrString = base64Url.encode(utf8.encode(jsonEncode(jsonMapTamperedName)));

   final importedTampered = identityService.importFromQr(tamperedQrString);
   // importedTampered.displayName is 'Mallory_Spoofed', NO Exception is thrown!
   ```
5. **Impact**: An attacker who intercepts or displays a spoofed QR code can substitute the victim's display name or inject a rogue secret key without triggering any integrity or verification error during import.

---

## 3. Caveats

- **Placeholder E2E Cryptography**: The current implementation of `E2eCryptoService` uses a XOR keystream derived from SHA256 blocks for simulation purposes (`PlaceholderE2eCryptoService`), rather than libsodium / X25519-Ed25519 / AES-256-GCM. While HMAC-SHA256 authentication tag checks are functionally correct, production code should upgrade to standard AEAD primitives (e.g. `chachapoly20` or `aes-256-gcm`).
- **Matrix ID Filter Scope**: `LocalIdentity` and `ContactAddress` validate against `@user:server` syntax, but do not parse complex matrix URI schemes (`matrix:u/...`).

---

## 4. Conclusion

1. **E2E Cryptography Correctness**: **PASS**. `PlaceholderE2eCryptoService` correctly encrypts and decrypts random byte payloads (0 B to 64 KB) and strictly enforces 1-byte tamper detection across nonces, MAC tags, ciphertext payloads, and public/secret key mismatches.
2. **Keypair & Base58 Invariants**: **PASS**. Keypairs generate 32-byte public keys and 64-byte secret keys with deterministic SHA-256 fingerprints and zero collisions across 150+ iterations.
3. **Domain Models Serialization**: **PASS**. `MessageEnvelope`, `ContactAddress`, and `Conversation` models perform lossless JSON round-trips under property testing.
4. **Vulnerability Identified**: **MEDIUM RISK**. `OfflineIdentityService.exportToQr()` lacks payload integrity protection (HMAC or signature over the QR payload), allowing stealth tampering of display names or secret keys during QR code import without detection.

---

## 5. Verification Method

To independently run and verify the property test suite:

```bash
cd /home/tommy/messaging
flutter test test/core/domain_crypto_property_test.dart
```

### Invalidation Conditions
- If any test in `test/core/domain_crypto_property_test.dart` fails or throws an unhandled exception.
- If modifying 1 byte in ciphertext fails to throw `FormatException`.
- If `decryptPayload` returns corrupted bytes for any random byte array.
