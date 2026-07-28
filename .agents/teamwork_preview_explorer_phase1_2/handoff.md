# Investigation Findings & Concrete Recommendations: Requirements R2 & R4

## 1. Observation

### Requirement R2: Auth UI & BLoC for P2P Identity
- **File:** `lib/features/auth/presentation/screens/auth_screen.dart`
  - **Line 123:** Header text is currently `'MATRIX // AUTH'`. Needs to be changed to `'P2P MATRIX // LOCAL IDENTITY GENERATOR'`.
  - **Lines 184-185:** Tab titles are `Tab(text: "IDENTITY_LOGIN")` and `Tab(text: "GENERATE_KEY")`. Need to be updated to `Tab(text: "LOCAL IDENTITY")` and `Tab(text: "CREATE P2P KEYPAIR")`.
  - **Lines 192-202:** Displays `"TARGET NET-NODE"` header and `CustomServerTextField(controller: _serverController)`.
  - **Lines 212-265:** TabBarView contains fields for remote login (Username & Passphrase) and registration (Desired Username & Master Passphrase).
  - **Lines 273-302:** TextButton executes `_executeAuthAction` which dispatches `LoginRequested` or `RegisterRequested` with `node` parameter.
- **File:** `lib/features/auth/presentation/bloc/auth_bloc.dart`
  - **Lines 7-19:** `LoginRequested` and `RegisterRequested` events take `node`, `username`, and `password`.
  - **Lines 44-70:** Handlers call `_authService.login` and `_authService.register` targeting a remote homeserver.
  - **Lines 83-92:** `_cleanErrorMessage` checks for remote HTTP errors like `M_USER_IN_USE`, `M_FORBIDDEN`, and `SocketException`.
- **File:** `lib/features/auth/data/matrix_auth_service.dart`
  - **Lines 63-106:** `register` and `login` methods validate homeserver URL and call remote Matrix server endpoints.

### Requirement R4: Storage Zeroization & Key Backup
- **File:** `lib/features/settings/presentation/screens/settings_screen.dart`
  - **Lines 18-34:** `_executeLocalMemorySanitization()` contains TODO stubs:
    ```dart
    void _executeLocalMemorySanitization() {
      // TODO: Direct operational hooks:
      // 1. Hive.deleteFromDisk()
      // 2. database.close() -> deleteDatabase(dbPath)
      // 3. flutter_secure_storage.deleteAll()
      // 4. exit(0) or Route back to baseline AuthState pipeline
    ```
  - **Lines 91-98:** `KeyManagementCards` callbacks `onExportKeys` and `onImportKeys` contain empty TODO stubs:
    ```dart
    KeyManagementCards(
      onExportKeys: () {
        // TODO: Wire up to File system access pipelines
      },
      onImportKeys: () {
        // TODO: Wire up to encrypted JSON import parser
      },
    ),
    ```
  - **Lines 108-110:** `PanicButton` triggers modal confirmation dialog that calls `_executeLocalMemorySanitization()`.
- **File:** `lib/features/settings/presentation/widgets/panic_button.dart`
  - **Lines 41-43:** Modal dialog triggers `onZeroizeConfirmed()` upon user approval.
- **File:** `lib/features/settings/presentation/widgets/key_management_cards.dart`
  - **Lines 52 & 66:** Renders `EXPORT_KEYS` and `IMPORT_KEYS` outlined buttons.

---

## 2. Logic Chain

### 2.1 Logic Chain for Requirement R2 (Auth UI & BLoC for P2P Identity)
1. **Serverless Architecture Context:** In Option B (Serverless P2P Architecture), identity generation is performed locally (Ed25519 keypair) and network traffic is routed through the local loopback connector (`http://127.0.0.1:8008`).
2. **UI Updates (`auth_screen.dart`):**
   - Updating header text to `'P2P MATRIX // LOCAL IDENTITY GENERATOR'` accurately conveys local key generation.
   - Updating tab titles to `"LOCAL IDENTITY"` (unlock/load existing local session) and `"CREATE P2P KEYPAIR"` (generate new Ed25519 keypair) aligns navigation tabs with P2P identity workflows.
   - Removing `CustomServerTextField` (or replacing it with a read-only indicator for `http://127.0.0.1:8008`) prevents users from attempting to configure remote homeservers, enforcing local P2P loopback.
3. **BLoC Logic Updates (`auth_bloc.dart`):**
   - Remote HTTP authentication handlers (`_authService.login`/`register`) must be replaced with local keypair generation (`GenerateKeyPairRequested`) and local identity loading (`LoadLocalIdentityRequested`).
   - `AuthBloc` should interact with `MatrixAuthService.generateLocalIdentity(username: event.username)` which persists the identity directly to local SQLite (`secure_matrix_store.db`).

### 2.2 Logic Chain for Requirement R4 (Storage Zeroization & Key Backup)
1. **Storage Zeroization (Panic Button):**
   - To achieve complete zeroization:
     a) Active Matrix client and SQLite database connection must be closed (`database.close()`).
     b) `secure_matrix_store.db` file (along with `-wal` and `-shm` transaction logs) must be deleted using `sqflite.deleteDatabase(dbPath)`.
     c) Application support and cache directories must be recursively cleared.
     d) `AuthBloc` state must be reset to `Unauthenticated()` / `AuthInitial()`.
     e) Navigator must reset the route stack using `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false)` to prevent backwards navigation into cached screens.
2. **Key Backup (Export & Import Handlers):**
   - **Key Export (`onExportKeys`):**
     a) Prompt user for an export passphrase.
     b) Serialize master keypair / Megolm session keys into JSON format.
     c) Encrypt serialized JSON string using AES-GCM-256 with PBKDF2 key derivation.
     d) Output encrypted JSON string to clipboard or file.
   - **Key Import (`onImportKeys`):**
     a) Prompt user to paste encrypted JSON string and input decryption passphrase.
     b) Decrypt payload with AES-GCM-256, parse JSON, and validate structure.
     c) Restore keys into `MatrixAuthService` / SQLite key store.
     d) Refresh app state to activate imported identity.

---

## 3. Caveats

- **No Code Modifications Performed:** In accordance with the Explorer role (read-only investigation), no code changes were written to production files under `lib/`.
- **P2P Node Dependency:** Identity generation and login assume the underlying `MatrixAuthService` is configured to target `http://127.0.0.1:8008` as specified in M1 (`PROJECT.md`).
- **Cryptographic Library Choice for Key Backup:** Encrypted JSON backup format requires standard WebCrypto/PointyCastle or AES-GCM cipher routines. Standard Dart `crypto` or Flutter cryptography packages should be used for AES-GCM + PBKDF2 derivation.

---

## 4. Conclusion

### Concrete Recommendations for Implementer:

1. **For `auth_screen.dart` (R2):**
   - Replace line 123 text with `'P2P MATRIX // LOCAL IDENTITY GENERATOR'`.
   - Update tab 0 label (line 184) to `"LOCAL IDENTITY"` and tab 1 label (line 185) to `"CREATE P2P KEYPAIR"`.
   - Remove `CustomServerTextField` widget call (lines 192-202) and its associated `_serverController` to simplify UI and enforce local loopback.
   - Update execution button logic (line 274) to invoke `GenerateKeyPairRequested` on Tab 1 and `LoadLocalIdentityRequested` on Tab 0.

2. **For `auth_bloc.dart` (R2):**
   - Add `GenerateKeyPairRequested` event handling:
     ```dart
     on<GenerateKeyPairRequested>((event, emit) async {
       emit(AuthLoading());
       try {
         final userId = await _authService.generateLocalIdentity(username: event.username);
         emit(AuthSuccess(userId));
       } catch (e) {
         emit(AuthFailure("ERROR: KEY_GENERATION_FAILED // ${e.toString()}"));
       }
     });
     ```
   - Add `LoadLocalIdentityRequested` event handling for local SQLite store unlocking.

3. **For `settings_screen.dart` - Panic Button Zeroization (R4):**
   - Implement `_executeLocalMemorySanitization()`:
     ```dart
     Future<void> _executeLocalMemorySanitization() async {
       final authService = context.read<MatrixAuthService>();
       await authService.logout();
       
       final directory = await getApplicationSupportDirectory();
       final dbPath = p.join(directory.path, 'secure_matrix_store.db');
       await deleteDatabase(dbPath);
       
       if (await directory.exists()) {
         final files = directory.listSync();
         for (final f in files) {
           try { await f.delete(recursive: true); } catch (_) {}
         }
       }
       
       if (mounted) {
         context.read<AuthBloc>().add(LogoutRequested());
         Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.auth, (route) => false);
       }
     }
     ```

4. **For `settings_screen.dart` - Key Export / Key Import (R4):**
   - Implement `onExportKeys`: Prompt user for passphrase -> serialize local master keypair & session keys -> AES-GCM-256 encrypt -> copy/download JSON string.
   - Implement `onImportKeys`: Prompt user for encrypted JSON string & passphrase -> decrypt AES-GCM-256 -> parse JSON -> restore key store in `MatrixAuthService` -> reload session.

---

## 5. Verification Method

To verify these implementations during Phase 2 (Implementation):
1. **R2 UI & BLoC Verification:**
   - Launch app on `/auth` route.
   - Confirm header shows `P2P MATRIX // LOCAL IDENTITY GENERATOR`.
   - Confirm tabs show `LOCAL IDENTITY` and `CREATE P2P KEYPAIR`.
   - Confirm `CustomServerTextField` is absent.
   - Enter alias in `CREATE P2P KEYPAIR` tab and tap action button; verify state changes to `AuthLoading` then `AuthSuccess` navigating to `/chat-list`.
2. **R4 Storage Zeroization Verification:**
   - Navigate to Settings screen (`/settings`).
   - Tap `EXECUTE PANIC PROTOCOL (ZEROIZE)` and confirm in dialog.
   - Verify `secure_matrix_store.db` is deleted from filesystem (`ls -la ~/.config/...` or app support directory).
   - Verify screen navigation resets immediately to `AppRoutes.auth` (`/auth`) and back button is disabled.
3. **R4 Key Export/Import Verification:**
   - Tap `EXPORT_KEYS`, enter passphrase, verify encrypted JSON string is generated.
   - Tap `IMPORT_KEYS`, paste JSON string and passphrase, verify successful restoration.
