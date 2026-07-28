# Handoff Report — Build Environment & Storage Layer Exploration

## 1. Observation
1. **Container Execution Error**: Running `flutter analyze` and `dart analyze` via `run_command` in the sandboxed agent container failed with exit code `46`:
   > `2026/07/27 22:03:29.887683 system_key.go:147: cannot determine nfs usage in generateSystemKey: cannot parse mountinfo: incorrect number of fields, expected at least 10 but found 9`
   > `internal error, please report: running "flutter" failed: timeout waiting for snap system profiles to get updated`
2. **`pubspec.yaml` Direct Dependencies** (`/home/tommy/messaging/pubspec.yaml:30-45`):
   - `flutter`: `sdk: flutter`
   - `cupertino_icons`: `^1.0.8`
   - `matrix`: `7.1.2`
   - `flutter_bloc`: `^9.1.1`
   - `provider`: `^6.1.5`
   - `path_provider`: `^2.1.5`
   - `sqflite`: `^2.4.2`
   - `path`: `^1.9.1`
   - `mobile_scanner`: `^6.0.0`
   - `permission_handler`: `^11.3.1`
3. **`pubspec.lock` Transitive Dependencies** (`/home/tommy/messaging/pubspec.lock`):
   - `crypto`: `3.0.7` (Line 148, `dependency: transitive`)
   - `base58check`: `2.0.0` (Line 47, `dependency: transitive`)
   - `flutter_rust_bridge`: `2.3.0` (Line 220, `dependency: transitive`)
   - `pointycastle`: Not present in `pubspec.lock`.
   - `cryptography`: Not present in `pubspec.lock`.
   - `web_socket_channel`: Not present in `pubspec.lock`.
   - `flutter_secure_storage` / `sqflite_sqlcipher`: Not present in `pubspec.lock`.
4. **Storage Layer Code** (`/home/tommy/messaging/lib/features/auth/data/matrix_auth_service.dart:25-32`):
   ```dart
   final directory = await getApplicationSupportDirectory();
   final dbPath = p.join(directory.path, 'secure_matrix_store.db');

   final database = await MatrixSdkDatabase.init(
     'secure_matrix_store',
     database: await openDatabase(dbPath),
     fileStorageLocation: directory.uri,
   );
   ```
5. **P2P Transport Code** (`/home/tommy/messaging/lib/core/p2p/p2p_node_service.dart:92`):
   ```dart
   _server = await HttpServer.bind(InternetAddress.anyIPv4, p2pPort);
   ```
6. **Test Suite Mismatch** (`/home/tommy/messaging/test/features/auth/data/matrix_auth_service_test.dart:9` vs `lib/features/auth/data/matrix_auth_service.dart:9`):
   - Test expects: `expect(MatrixAuthService.defaultHomeserver, equals('http://127.0.0.1:8008'));`
   - Source defines: `static const String defaultHomeserver = 'https://matrix.org';`

---

## 2. Logic Chain
1. **Observation 1 & 2** show that the CLI build environment inside sandbox is restricted by Snap execution limits, requiring static inspection of `pubspec.yaml` and `pubspec.lock`.
2. **Observation 3** reveals that while basic hashing (`crypto: 3.0.7`) and base58check (`2.0.0`) are pulled in transitively by `matrix`, packages for asymmetric Ed25519/X25519 cryptography (`cryptography` or `pointycastle`), WebSocket transport adapters (`web_socket_channel`), and secure encrypted storage (`sqflite_sqlcipher` / `flutter_secure_storage`) are completely missing from both `pubspec.yaml` and `pubspec.lock`.
3. **Observation 4** demonstrates that SQLite databases (`secure_matrix_store.db`) are currently opened with `openDatabase` without encryption, creating a security gap for data stored at rest.
4. **Observation 5** demonstrates that P2P transport relies solely on raw HTTP REST over `dart:io` `HttpServer`/`HttpClient` rather than duplex WebSocket streaming.
5. **Observation 6** identifies an immediate test breakdown: unit tests fail because test fixtures expect `defaultHomeserver` to be `'http://127.0.0.1:8008'` while implementation specifies `'https://matrix.org'`.

---

## 3. Caveats
- **CLI Analyzer Runtime**: `flutter analyze` could not run directly in the sandboxed container due to host Snap system profile lock restrictions; conclusions are derived from manual AST and lockfile analysis.
- **Transitive Cryptography**: Matrix SDK internally uses `flutter_rust_bridge` to interface with native Rust Olm/Vodozemac binaries for Matrix E2EE, but this does not expose generic Dart-level Ed25519/X25519 keypair generation or local storage encryption for custom application payloads.

---

## 4. Conclusion
1. **Existing Dependencies**: The app has `matrix`, `sqflite`, `path_provider`, `flutter_bloc`, `provider`, `mobile_scanner`, and `permission_handler` directly configured.
2. **Required Package Additions**:
   - `cryptography: ^2.7.0` (for Ed25519 signature & X25519 Diffie-Hellman keypairs).
   - `base58: ^1.0.2` (for raw Base58 key/address encoding).
   - `sqflite_sqlcipher: ^3.1.0` and `flutter_secure_storage: ^9.2.4` (for hardware-backed encrypted storage at rest).
   - `web_socket_channel: ^3.0.1` (for WebSocket P2P / relay transport).
3. **Test Suite Fixes Needed**: Reconcile `MatrixAuthService.defaultHomeserver` constant between test assertions (`http://127.0.0.1:8008`) and implementation (`https://matrix.org`), and complete the stubbed test cases in `test/r1_stress_test.dart`.

---

## 5. Verification Method
1. **Pubspec Check**: Run `grep -E "cryptography|sqflite_sqlcipher|flutter_secure_storage|web_socket_channel|base58" /home/tommy/messaging/pubspec.yaml`. Verification fails if missing.
2. **Database Verification**: Inspect `/home/tommy/messaging/lib/features/auth/data/matrix_auth_service.dart:30` to check if `openDatabase` is replaced with an encrypted database factory.
3. **Test Constant Verification**: Compare line 9 of `/home/tommy/messaging/lib/features/auth/data/matrix_auth_service.dart` with line 9 of `/home/tommy/messaging/test/features/auth/data/matrix_auth_service_test.dart`.
