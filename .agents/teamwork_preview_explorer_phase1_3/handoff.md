# Handoff Report: Requirement R3 (P2P Node Service, QR Handshake, Status Bar)

## 1. Observation

### Observation 1.1: Core Directory Structure
- Current directory search (`find_by_name` on `lib/`) shows the following top-level subdirectories: `lib/config/`, `lib/features/`, `lib/theme/`, `lib/main.dart`.
- The `lib/core/` directory does **not** currently exist in the codebase.
- Matrix client initialization and DB session persistence are currently handled in `lib/features/auth/data/matrix_auth_service.dart` (lines 1-114). Specifically, `_normalizeUrl()` (lines 50-60) normalizes local IP addresses (`127.0.0.1`, `localhost`, `10.0.2.2`) with `http://`.

### Observation 1.2: New Chat Modal & QR Scanner Logic
- Inspecting `lib/features/chat/presentation/widgets/new_chat_modal.dart`:
  - Scanner callback `_onDetect()` (lines 75-102) handles barcode parsing. Line 87 contains regex:
    ```dart
    final regExp = RegExp(r'^@[a-zA-Z0-9_\-\.\=\/]+:[a-zA-Z0-9_\-\.]+\.[a-zA-Z]+');
    ```
    This regex strictly requires a dot and top-level domain (TLD) (`\.[a-zA-Z]+`), which causes validation to fail for P2P Matrix Public Key URIs without traditional TLDs (e.g., `@pubkey:yggdrasil`, `@key:p2p`, or `@key:127.0.0.1:8008`).
  - URI prefix stripping (lines 82-85) only handles `matrix:u/`.
  - Direct message room creation `_executeSecureHandshake()` (lines 104-144) calls:
    ```dart
    await authService.client.createRoom(
      invite: [remoteMatrixId],
      isDirect: true,
      preset: matrix.CreateRoomPreset.trustedPrivateChat,
      visibility: matrix.Visibility.private,
    );
    ```

### Observation 1.3: Status App Bar & Sync Indicator
- Inspecting `lib/features/chat/presentation/widgets/status_app_bar.dart`:
  - Displays subheader `"MATRIX PROTOCOL NODE"` (line 54) and text label `syncStatus.toUpperCase()` (line 77).
- Inspecting `lib/features/chat/presentation/screens/chat_list_screen.dart`:
  - Line 128 passes `syncStatus: "CONNECTED"` to `StatusAppBar`.
  - The text `"SERVER CONNECTED"` or `"CONNECTED"` is currently static and does not reflect P2P mesh status (`"P2P MESH ACTIVE"`).

---

## 2. Logic Chain

1. **P2P Node Service Design (`lib/core/p2p/p2p_node_service.dart`)**:
   - *Observation reference*: Obs 1.1 shows `lib/core/` does not exist and `MatrixAuthService` normalizes URLs for local loopback (`http://127.0.0.1:8008`).
   - *Deduction*: We need to create `lib/core/p2p/p2p_node_service.dart` as a singleton service managing the local P2P loopback connector target (`http://127.0.0.1:8008`).
   - *Architecture*:
     - Singleton pattern: `P2pNodeService._internal()`, `factory P2pNodeService() => _instance`.
     - Target Loopback: `http://127.0.0.1:8008`.
     - Reactive Status: `enum P2pNodeStatus { stopped, starting, active, error }` with a broadcast `Stream<P2pNodeStatus>`.
     - Methods: `startNode()`, `stopNode()`, `checkHealth()`, `formatPeerUserId()`.

2. **QR Scanner & Handshake Enhancements (`new_chat_modal.dart`)**:
   - *Observation reference*: Obs 1.2 shows regex `RegExp(r'^@[a-zA-Z0-9_\-\.\=\/]+:[a-zA-Z0-9_\-\.]+\.[a-zA-Z]+')` fails on P2P peer IDs like `@pubkey:yggdrasil`.
   - *Deduction*:
     - Update regex to support non-TLD P2P domains: `RegExp(r'^@[a-zA-Z0-9_\-\.\=\/]+:[a-zA-Z0-9_\-\.\:\/]+$')`.
     - Expand URI scheme parsing to extract user IDs from `matrix:u/pubkey:yggdrasil`, `matrix:u/pubkey:yggdrasil?action=chat`, and `p2p:u/pubkey:yggdrasil`.
     - Ensure `_executeSecureHandshake()` validates input, uses `CreateRoomPreset.trustedPrivateChat`, and handles E2EE initial state setup (`m.room.encryption`).

3. **Status Bar Indicator Update (`status_app_bar.dart` & `chat_list_screen.dart`)**:
   - *Observation reference*: Obs 1.3 shows static `syncStatus: "CONNECTED"` in `chat_list_screen.dart`.
   - *Deduction*:
     - Update `StatusAppBar` default text or `chat_list_screen.dart` invocation to `"P2P MESH ACTIVE"`.
     - Bind status indicator to `P2pNodeService` status so green dot and label reflect active P2P mesh state.

---

## 3. Caveats

- **Network Mode**: The investigation was conducted in CODE_ONLY mode without active network connections to a live Yggdrasil P2P daemon. Local loopback health checks simulate `http://127.0.0.1:8008`.
- **E2EE Crypto Session Establishment**: Handshake room creation via `createRoom` relies on Matrix SDK (`matrix: 7.1.2`). Peer key exchange happens over the P2P loopback server.

---

## 4. Conclusion

The implementation of Requirement R3 requires three concrete changes:
1. Create `lib/core/p2p/p2p_node_service.dart` providing singleton management of `http://127.0.0.1:8008` loopback node status and health checks.
2. Update `lib/features/chat/presentation/widgets/new_chat_modal.dart` to support P2P Matrix Public Key URIs (e.g. `@pubkey:yggdrasil`, `matrix:u/pubkey:yggdrasil`) by removing rigid TLD regex restrictions and preserving `CreateRoomPreset.trustedPrivateChat` direct channel handshake logic.
3. Update `lib/features/chat/presentation/widgets/status_app_bar.dart` and `chat_list_screen.dart` to display `"P2P MESH ACTIVE"` when connected to local P2P loopback node.

---

## 5. Verification Method

To verify the implementation once written:
1. Inspect file existence of `lib/core/p2p/p2p_node_service.dart`.
2. Run `flutter analyze` from `/home/tommy/messaging` to ensure zero compilation or lint errors.
3. Run `flutter test` to execute test suite.
4. Verify regex in `new_chat_modal.dart` against sample inputs:
   - `@0123456789abcdef:yggdrasil` -> Valid
   - `matrix:u/pubkey:yggdrasil` -> Valid (parsed to `@pubkey:yggdrasil`)
   - `@user:matrix.org` -> Valid
