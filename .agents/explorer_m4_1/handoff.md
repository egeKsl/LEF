# Milestone 4 - UI Features & BLoCs Integration (Auth & Settings) Refactoring Plan

## 1. Observation

### 1.1 Scope & Directory Structure
- Working directory: `/home/tommy/messaging/.agents/explorer_m4_1`
- Auth feature directory: `lib/features/auth/`
  - `presentation/bloc/auth_bloc.dart`
  - `presentation/screens/auth_screen.dart`
  - `presentation/widgets/auth_text_field.dart`
  - `presentation/widgets/custom_server_text_field.dart`
- Settings feature directory: `lib/features/settings/`
  - `presentation/screens/settings_screen.dart`
  - `presentation/widgets/key_management_cards.dart`
  - `presentation/widgets/panic_button.dart`
  - `presentation/widgets/tor_switch_tile.dart`
- Domain / Core dependencies:
  - `lib/core/identity/identity_service.dart` (`IdentityService`, `OfflineIdentityService`)
  - `lib/core/identity/local_identity.dart` (`LocalIdentity`)
  - `lib/core/identity/base58.dart` (`Base58`)
  - `lib/core/transport/transport_adapter.dart` (`TransportAdapter`, `TransportConnectionState`)
  - `lib/core/transport/relay_transport_adapter.dart` (`RelayTransportAdapter`)
  - `lib/core/storage/local_storage_repository.dart` (`LocalStorageRepository`)
  - `lib/core/storage/database_service.dart` (`DatabaseService`)

### 1.2 Auth Feature Direct Code Inspection
1. **`auth_bloc.dart`**:
   - Lines 18-30 define legacy server authentication events: `LoginRequested` and `RegisterRequested`, each accepting `node`, `username`, `password`.
   - Line 3: Directly imports `import '../../../../core/storage/local_storage_repository.dart';`, violating UI/BLoC domain boundary rules.
   - Event handlers for `LoginRequested` and `RegisterRequested` (lines 83-103) call `generateIdentity` internally, but maintain the misleading server/login API interface.
2. **`auth_screen.dart`**:
   - Lines 20-22: Declares controllers `_homeserverController` (default `wss://relay.example.com`), `_usernameController`, `_passwordController`.
   - Lines 177-181: Provides `TabBar` with `REGISTER` and `LOGIN` tabs.
   - Lines 195-236 & 250-292: Renders forms containing `RELAY SERVER URL`, `USERNAME`, and `PASSWORD` input fields.
   - Completely lacks UI for:
     - Displaying local keypair public key fingerprint (Base58/Base64).
     - QR code generation and display.
     - QR code import (pasting Base64 payload or camera scan).
3. **`custom_server_text_field.dart`**:
   - Line 38 contains hint text: `hintText: 'https://matrix.org or your homeserver'`. Matrix user ID formats (`@user:server`) and Matrix homeserver paradigms are strictly prohibited in the decentralized core specification.

### 1.3 Settings Feature Direct Code Inspection
1. **`settings_screen.dart`**:
   - Lines 5-7: Directly imports core storage and identity services:
     - `import '../../../../core/identity/identity_service.dart';`
     - `import '../../../../core/storage/database_service.dart';`
     - `import '../../../../core/storage/local_storage_repository.dart';`
   - Lines 22-43: Instantiates `DatabaseService()` directly inside UI method `_executeLocalMemorySanitization()`.
   - Lines 45-102: Instantiates `LocalStorageRepository()` and `OfflineIdentityService()` directly inside UI method `_handleExportKeys()`.
   - Lines 104-178: Instantiates `LocalStorageRepository()` and `OfflineIdentityService()` directly inside UI method `_handleImportKeys()`.
   - Lines 20-21: Manages local `setState` for `_isTorNetworkActive` without BLoC state management.
   - **Missing Requirements**:
     - No Relay Server URL text input field linked to `RelayTransportAdapter` configuration.
     - No real-time connection status widget tracking `TransportConnectionState` (`disconnected`, `connecting`, `connected`, `error`).

### 1.4 Architectural Boundary Violations (Direct `core/storage` or `core/transport` imports in UI/BLoCs)
A project-wide search (`grep_search`) identified the following direct storage imports in presentation/BLoC layers:
- `lib/features/auth/presentation/bloc/auth_bloc.dart`: Line 3 (`local_storage_repository.dart`)
- `lib/features/settings/presentation/screens/settings_screen.dart`: Lines 6 & 7 (`database_service.dart`, `local_storage_repository.dart`)
- `lib/features/chat/presentation/screens/chat_list_screen.dart`: Line 3 (`local_storage_repository.dart`)
- `lib/features/chat/presentation/widgets/new_chat_modal.dart`: Line 7 (`local_storage_repository.dart`)
- `lib/features/chat_room/presentation/screens/chat_room_screen.dart`: Line 4 (`local_storage_repository.dart`)
- `lib/features/chat_room/presentation/widgets/message_stream.dart`: Line 3 (`local_storage_repository.dart`)

---

## 2. Logic Chain

### 2.1 Refactoring `AuthBloc` & `AuthScreen`
1. **Eliminating Server & Matrix Paradigms**:
   - Central logins, registrations, server URLs, and passwords are fully obsolete in an offline-first, decentralized P2P architecture.
   - Refactor `AuthBloc` events:
     - `GenerateLocalIdentityRequested({required String displayName})`: Generates Ed25519/X25519 keypair offline via `OfflineIdentityService`.
     - `ImportIdentityFromQrRequested({required String qrPayload})`: Parses Base64/JSON identity string via `OfflineIdentityService.importFromQr`.
     - `LoadExistingIdentityRequested()`: Checks local identity storage on app startup.
     - `DeleteLocalIdentityRequested()`: Clears identity on logout.
   - Refactor `AuthState`:
     - `AuthInitial`: Uninitialized state.
     - `AuthLoading`: Processing key generation or import.
     - `AuthUnauthenticated`: No local identity present; prompt onboarding.
     - `AuthAuthenticated(LocalIdentity identity)`: Active identity loaded, containing `publicKey`, `secretKey`, `fingerprint`, `displayName`.
     - `AuthFailure(String message)`: Error during generation or import validation.

2. **UI Onboarding & Presentation in `AuthScreen`**:
   - Replace the `REGISTER` / `LOGIN` tabs with tactical decentralized onboarding tabs:
     - **TAB 1: CREATE NEW IDENTITY**
       - Input field: `DISPLAY NAME / KEY ALIAS` (e.g. `alice`). Validates that input is non-empty and does NOT contain `@` or `:`.
       - Action: `GENERATE OFFLINE KEYPAIR`.
       - Result View: Renders local cryptographic keypair details:
         - Public Key Fingerprint (Base58 string).
         - Tactical QR Code view (Base64 encoded payload rendered visually).
         - Copy Fingerprint / Copy QR payload buttons.
     - **TAB 2: IMPORT EXISTING IDENTITY**
       - Input field: Multi-line text field for pasting exported QR payload string (Base64 URL format).
       - Action: `IMPORT IDENTITY PAYLOAD`.
       - Validation: Uses `OfflineIdentityService.importFromQr` to verify cryptographic fingerprint matching SHA-256 hash of the public key.

### 2.2 Refactoring `SettingsScreen` & Settings BLoC
1. **Relay Server URL & Transport Monitoring**:
   - `RelayTransportAdapter` (`lib/core/transport/relay_transport_adapter.dart`) manages connection to a configurable relay URL and emits `Stream<TransportConnectionState>`.
   - Introduce `SettingsBloc` (or `SettingsCubit`) to manage settings domain state cleanly:
     - Events: `LoadSettingsRequested`, `UpdateRelayUrlRequested(String relayUrl)`, `ToggleTorRequested(bool enabled)`, `ExportIdentityRequested`, `ImportIdentityRequested(String qrPayload)`, `ExecutePanicPurgeRequested`.
     - State: `SettingsState` containing `relayUrl`, `connectionState` (`disconnected`, `connecting`, `connected`, `error`), `isTorEnabled`, `currentIdentity`, `statusMessage`.
   - `SettingsScreen` UI components:
     - **Relay Configuration Section**:
       - Text field for Relay Server URL (pre-filled with active URL, e.g. `wss://relay.example.com`).
       - Button: `APPLY RELAY CONFIG`.
       - Status Indicator Badge: Real-time badge reflecting `connectionState`:
         - `disconnected` -> Muted Grey/Orange (`DISCONNECTED`)
         - `connecting` -> Cyber Blue (`CONNECTING...`)
         - `connected` -> Crypto Green (`CONNECTED // ACTIVE`)
         - `error` -> Panic Red (`CONNECTION ERROR`)
     - **Tor Proxy Tunneling Section**: Uses `TorSwitchTile` linked to BLoC event.
     - **Security & Key Management Section**: Uses `KeyManagementCards` with QR payload dialog / copy dialog linked to BLoC events.
     - **Destructive Actions Section**: Uses `PanicButton` linked to BLoC event `ExecutePanicPurgeRequested`.

### 2.3 Strict Architecture & Import Decoupling
1. **Decoupling Rule**:
   - Presentation widgets (`lib/features/*/presentation/`) must NEVER directly import `lib/core/storage/` (`database_service.dart`, `local_storage_repository.dart`) or `lib/core/transport/` (`relay_transport_adapter.dart`).
2. **Dependency Injection & Access Pattern**:
   - Domain services (`IdentityService`, `LocalStorageRepository`, `TransportAdapter`) are injected into BLoCs (`AuthBloc`, `SettingsBloc`) at root level (`main.dart`).
   - UI widgets interact with BLoCs via `BlocBuilder`, `BlocConsumer`, and `context.read<AuthBloc>()` / `context.read<SettingsBloc>()`.

---

## 3. Caveats
- No caveats regarding key generation or cryptographic integrity logic (fully implemented in `lib/core/identity/offline_identity_service.dart`).
- QR code rendering can be achieved either via string payload viewer / selectable container or integrating `qr_flutter`. For offline QR import, pasting Base64 payload string or reading camera inputs through BLoC works cross-platform.
- In validation, ensure display names and relay URLs do not accept Matrix user ID formats (`@user:server`).

---

## 4. Conclusion
- The refactoring plan for `AuthBloc`, `AuthScreen`, `SettingsScreen`, and `SettingsBloc` provides a completely serverless, offline-first identity and transport configuration architecture.
- Central server and Matrix references are eliminated.
- Direct core storage/transport imports in UI widgets are replaced with BLoC-driven clean architecture.

---

## 5. Verification Method

### 5.1 Verification Commands
1. **Static Analysis & Lint Verification**:
   ```bash
   flutter analyze
   ```
   Ensure 0 warnings/errors regarding unused imports or invalid references.

2. **Direct Import Grep Audit**:
   ```bash
   # Verify no UI widgets import core/storage or core/transport directly:
   grep -rn "import.*core/storage" lib/features/*/presentation/
   grep -rn "import.*core/transport" lib/features/*/presentation/
   ```
   Expected output: 0 results.

3. **Automated Unit & BLoC Test Suite**:
   ```bash
   flutter test
   ```
   Ensures all identity, transport, storage, and BLoC tests execute cleanly.

### 5.2 Specific Files to Inspect
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/screens/auth_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/bloc/settings_bloc.dart` (new)
- `lib/main.dart`
