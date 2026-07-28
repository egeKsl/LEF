# Comprehensive Architecture Analysis: UI & BLoC Structure

**Date**: 2026-07-27
**Explorer**: UI & BLoC Architecture Explorer (`teamwork_preview_explorer_m0_2`)
**Target Directory**: `/home/tommy/messaging/lib/`

---

## 1. Structure of `lib/features/` & State Management Inventory

### 1.1 Overview of Files in `lib/`
The project follows a feature-first architectural pattern (`auth`, `chat`, `chat_room`, `settings`) along with `core`, `config`, and `theme` layers:

```
lib/
├── config/
│   └── routes/
│       └── app_routes.dart
├── core/
│   └── p2p/
│       └── p2p_node_service.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── matrix_auth_service.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── auth_bloc.dart
│   │       ├── screens/
│   │       │   └── auth_screen.dart
│   │       └── widgets/
│   │           ├── auth_text_field.dart
│   │           └── custom_server_text_field.dart
│   ├── chat/
│   │   ├── data/
│   │   │   └── mock_chat_data.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── chat_list_screen.dart
│   │       └── widgets/
│   │           ├── encrypted_chat_tile.dart
│   │           ├── new_chat_modal.dart
│   │           └── status_app_bar.dart
│   ├── chat_room/
│   │   ├── data/
│   │   │   ├── isolate_decoder_service.dart
│   │   │   └── mock_chat_room_messages.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── chat_room_screen.dart
│   │       └── widgets/
│   │           ├── custom_data_decoder_widget.dart
│   │           ├── key_verification_dialog.dart
│   │           ├── message_stream.dart
│   │           ├── mock_message_stream.dart
│   │           └── secure_input_bar.dart
│   └── settings/
│       └── presentation/
│           ├── screens/
│           │   └── settings_screen.dart
│           └── widgets/
│               ├── key_management_cards.dart
│               ├── panic_button.dart
│               └── tor_switch_tile.dart
├── theme/
│   └── secure_colors.dart
└── main.dart
```

### 1.2 Inventory of BLoCs, Cubits, and Repositories

| Component | Type | Location | Responsibilities |
|---|---|---|---|
| `AuthBloc` | Flutter `Bloc` (`Bloc<AuthEvent, AuthState>`) | `lib/features/auth/presentation/bloc/auth_bloc.dart` | Handles identity generation, login, registration, and logout via `MatrixAuthService` and updates user ID on `P2pNodeService`. |
| `MatrixAuthService` | Data Service / Client Wrapper | `lib/features/auth/data/matrix_auth_service.dart` | Wraps Matrix SDK `Client` and `MatrixSdkDatabase`, manages initialization, active session checks, authentication, export/import of key metadata, and local database purging. |
| `P2pNodeService` | Singleton Service | `lib/core/p2p/p2p_node_service.dart` | Embedded HTTP server listening on port 8008 for local Wi-Fi mesh socket communication, message broadcasting, and peer discovery streams. |
| `IsolateDecoderService` | Utility Service | `lib/features/chat_room/data/isolate_decoder_service.dart` | Runs heavy cryptographic/visual payload decoding in an isolated background thread via Flutter `compute`. |

*Note*: There are currently **no Repositories or additional BLoCs/Cubits** in the codebase. State management in `chat`, `chat_room`, and `settings` relies directly on Flutter widgets (`StatefulWidget`, `StreamBuilder`, `Provider.of<MatrixAuthService>`) and mock data toggles.

---

## 2. Wiring of State Management to Matrix & P2P Singletons

### 2.1 Dependency Injection & Tree Provision
- In `lib/main.dart`:
  - `MatrixAuthService` is instantiated and initialized (`await matrixAuthService.init()`).
  - `MultiProvider` injects `Provider<MatrixAuthService>.value(value: matrixAuthService)` and `BlocProvider<AuthBloc>(create: (context) => AuthBloc(matrixAuthService))`.
  - `P2pNodeService` is NOT injected via Provider; it is implemented as a global singleton (`P2pNodeService()`) and accessed directly across modules.

### 2.2 Direct Coupling Details
1. **`AuthBloc`**:
   - Calls `MatrixAuthService` for `generateLocalIdentity`, `login`, `register`, `logout`.
   - On successful authentication, explicitly calls `P2pNodeService().setCurrentUserId(userId)` (e.g. lines 62, 75, 90, 105 in `auth_bloc.dart`).
2. **`ChatListScreen`**:
   - Obtains `MatrixAuthService` via `Provider.of<MatrixAuthService>(context, listen: false)`.
   - Uses `StreamBuilder<matrix.SyncUpdate>` to listen to `authService.client.onSync.stream` and map `authService.client.rooms` into UI tiles when `kDisableMocksForProduction` flag is false.
3. **`NewChatModal`**:
   - Obtains `MatrixAuthService` via `Provider.of<MatrixAuthService>(context, listen: false)`.
   - Calls `P2pNodeService().getPeerIp(...)` and `P2pNodeService().sendHandshakeToIp(...)` for P2P handshake.
   - Calls `authService.client.createRoom(...)` for standard Matrix room creation.
4. **`ChatRoomScreen`**:
   - In P2P / Mock mode: subscribes to `P2pNodeService().onMessageReceived` stream and sends messages via `P2pNodeService().sendMessage(...)`.
   - In Matrix room mode: passes `matrix.Room` to `MessageStream`, which calls `widget.room.getTimeline()`. Sends messages via `widget.room.sendTextEvent(...)`.
5. **`SettingsScreen`**:
   - Obtains `MatrixAuthService` via Provider to invoke `exportMasterKeys()`, `importMasterKeys()`, and `purgeLocalStore()`.

---

## 3. Data Fetching, Navigation, Onboarding, and Settings Flows

### 3.1 Onboarding & Navigation Flow
- **Entry Point**: `lib/main.dart`
  - Initializes `MatrixAuthService`.
  - Calls `matrixAuthService.hasActiveSession()`.
  - If `isLoggedIn` is true -> initial route is `AppRoutes.chatList` (`/chat-list`).
  - If `isLoggedIn` is false -> initial route is `AppRoutes.auth` (`/auth`).
- **Auth Screen (`AppRoutes.auth`)**:
  - Two tabs: `REGISTER` and `LOGIN`.
  - Submits `RegisterRequested` or `LoginRequested` events to `AuthBloc`.
  - `BlocConsumer` listens for `AuthSuccess` and executes `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.chatList, (route) => false)`.
- **Chat List Screen (`AppRoutes.chatList`)**:
  - Displays conversation channels.
  - Floating Action Button (FAB) opens `NewChatModal` via `showModalBottomSheet`.
  - Tapping a conversation tile pushes `ChatRoomScreen` dynamically via `Navigator.push(context, MaterialPageRoute(...))`.
  - Tapping settings icon in `StatusAppBar` calls `Navigator.pushNamed(context, AppRoutes.settings)`.
- **Chat Room Screen**:
  - Displays message stream and input bar.
  - Shield icon in App Bar triggers `KeyVerificationDialog.show(...)` for interactive SAS emoji verification.
  - Back arrow executes `Navigator.pop(context)`.
- **Settings Screen (`AppRoutes.settings`)**:
  - Features Tor proxy toggle, export/import key dialogs, and a Panic Button.
  - Triggering Panic Zeroize calls `authService.purgeLocalStore()` and resets navigation back to `AppRoutes.auth`.

### 3.2 Data Fetching Mechanics
- **Mock vs. Live Toggles**:
  - `ChatListScreen` has `const bool kDisableMocksForProduction = false;` (Line 15 in `chat_list_screen.dart`). Note: line 134 uses `kDisableMocksForProduction ? _tilesFromMock(...) : StreamBuilder(...)`.
  - `ChatRoomScreen` checks `_useMock` (true when `mockPreview != null`). If true, renders `MockMessageStream`; if false, renders `MessageStream(room: widget.room!)`.

---

## 4. Architectural Gaps & Required Changes in `features/`

To transition from Matrix-centric / mock-assisted architecture to a decoupled, local-first keypair & SQLite architecture:

### 4.1 Keypair Identity Support (`features/auth/`)
- **Current Limitation**: Identity generation relies on `MatrixAuthService.generateLocalIdentity()`, which registers a dummy user on a Matrix homeserver using HTTP calls (`_client!.register(...)`).
- **Required Changes**:
  - Abstract identity generation behind an `IdentityRepository` interface (`lib/core/identity/` or `lib/features/auth/domain/repositories/`).
  - Update `AuthBloc` with new events: `CreateLocalKeypairRequested`, `ImportKeypairRequested`, `LoadSavedIdentityRequested`.
  - Modify `AuthScreen` to offer a "Local Cryptographic Keypair" mode (generating Ed25519/X25519 or Secp256k1 keypairs offline without needing any homeserver URL).
  - Securely store keypair private keys in secure storage (`flutter_secure_storage` or encrypted local store).

### 4.2 Local SQLite Storage Integration (`features/chat/` & `features/chat_room/`)
- **Current Limitation**: Persistence is managed inside Matrix SDK (`MatrixSdkDatabase` wrapping `sqflite` at `secure_matrix_store.db`). UI screens reference `matrix.Room` and `matrix.Timeline` directly.
- **Required Changes**:
  - Create a custom `LocalDatabaseRepository` using `sqflite` to persist:
    - `contacts` (public keys, aliases, IP/relay mappings, trust status)
    - `conversations` (channel ID, peer ID, last message, unread count)
    - `messages` (id, conversation_id, sender_id, body, timestamp, status, ephemerality)
  - Introduce domain models (`ConversationEntity`, `MessageEntity`) to decouple UI from Matrix SDK types.
  - Create new BLoCs/Cubits:
    - `ChatListBloc` / `ChatListCubit`: Emits `ChatListLoaded(List<ConversationEntity>)`, listens to local DB updates and P2P incoming message streams.
    - `ChatRoomBloc` / `ChatRoomCubit`: Handles message sending, local DB insertion, timeline pagination, and message ephemerality timers.

### 4.3 Contact Address Modal (`features/chat/presentation/widgets/new_chat_modal.dart`)
- **Current Limitation**: Accepts Matrix User IDs (`@user:server`) and legacy IP addresses (`192.168.x.x`).
- **Required Changes**:
  - Update input field and QR scanner validation regex in `NewChatModal` to support:
    - Hex public keys (64 characters)
    - Bech32 public key formats (e.g. `npub1...` or `addr1...`)
    - P2P IPv4/IPv6 addresses and onion addresses (`.onion`)
  - Add a "Save Contact" action that inserts the new contact into local SQLite storage via `ContactRepository`.

### 4.4 Relay & Network Node Configuration (`features/settings/`)
- **Current Limitation**: `SettingsScreen` has a hardcoded `TorSwitchTile` with local state `_isTorNetworkActive = false;` and no relay configuration.
- **Required Changes**:
  - Create a dedicated "RELAY & MAPPING CONFIGURATION" section in `SettingsScreen`.
  - Implement a `RelayConfigurationCard` widget allowing users to:
    - View active P2P listening port (e.g., 8008) and local IPv4/IPv6 interfaces.
    - Add/remove remote relay URLs (e.g. WebSocket relays `wss://...` or P2P seed nodes).
    - Toggle relay connections.
  - Create a `RelayBloc` or `NetworkSettingsCubit` to manage relay state and notify `P2pNodeService` / relay transport handlers.

---

## 5. Summary Table of Required File Modifications

| File / Component | Required Modifications |
|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Support local keypair identity events/states without homeserver dependency. |
| `lib/features/auth/presentation/screens/auth_screen.dart` | Update tab UI to support offline keypair creation/import alongside Matrix login. |
| `lib/features/chat/presentation/screens/chat_list_screen.dart` | Replace direct `matrix.Room` / `StreamBuilder` logic with `ChatListBloc` and local SQLite repository streams. |
| `lib/features/chat/presentation/widgets/new_chat_modal.dart` | Support public key / address validation and direct local SQLite contact saving. |
| `lib/features/chat_room/presentation/screens/chat_room_screen.dart` | Replace `matrix.Room` dependency with `ChatRoomBloc` and unified `ConversationEntity`. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add relay configuration section, wire `TorSwitchTile` and key management to state managers. |
| `lib/features/settings/presentation/widgets/` | Create `relay_configuration_card.dart` for managing P2P seed nodes and relay URLs. |
| `lib/main.dart` | Inject new BLoCs (`ChatListBloc`, `SettingsBloc`) and local database repository services into `MultiProvider`. |
