# Handoff Report: UI & BLoC Architecture Exploration

## 1. Observation
Directly observed codebase state across `/home/tommy/messaging/lib/`:
- **State Management & DI Setup**:
  - `lib/main.dart` (lines 12-28):
    ```dart
    final matrixAuthService = MatrixAuthService();
    await matrixAuthService.init();
    final isLoggedIn = await matrixAuthService.hasActiveSession();
    final initialRoute = isLoggedIn ? AppRoutes.chatList : AppRoutes.auth;
    runApp(
      MultiProvider(
        providers: [
          Provider<MatrixAuthService>.value(value: matrixAuthService),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(matrixAuthService),
          ),
        ],
        child: MyApp(initialRoute: initialRoute),
      ),
    );
    ```
- **BLoCs & Services**:
  - `lib/features/auth/presentation/bloc/auth_bloc.dart`: Contains the only BLoC in the project (`AuthBloc`). Handles `GenerateLocalIdentityRequested`, `CreateP2pKeyPairRequested`, `LoginRequested`, `RegisterRequested`, `LogoutRequested`. Calls `P2pNodeService().setCurrentUserId(userId)` on auth success.
  - `lib/core/p2p/p2p_node_service.dart` (lines 52-57): `P2pNodeService` is a global singleton managing local Wi-Fi mesh sockets on HTTP port 8008.
- **Chat & Room UI Data Wiring**:
  - `lib/features/chat/presentation/screens/chat_list_screen.dart` (lines 134-149): Switches between `_tilesFromMock(context)` and `StreamBuilder<matrix.SyncUpdate>` on `authService.client.onSync.stream`.
  - `lib/features/chat_room/presentation/screens/chat_room_screen.dart` (lines 55-68, 88-91): Subscribes to `P2pNodeService().onMessageReceived.listen` and sends messages via `P2pNodeService().sendMessage(...)` when in mock/P2P mode, or uses `matrix.Room` and `MessageStream` when in Matrix mode.
- **Settings & Panic Protocol**:
  - `lib/features/settings/presentation/screens/settings_screen.dart` (lines 22-44): Calls `authService.purgeLocalStore()` (deletes SQLite `secure_matrix_store.db`) and navigates to `AppRoutes.auth`.

## 2. Logic Chain
1. **Observation**: `AuthBloc` is the single BLoC component in the current codebase; `chat`, `chat_room`, and `settings` rely on `StatefulWidget`s, `StreamBuilder`s, and `Provider.of<MatrixAuthService>`.
2. **Observation**: `P2pNodeService` is accessed directly as a global singleton, whereas `MatrixAuthService` is provided via `MultiProvider`.
3. **Observation**: `ChatListScreen` and `ChatRoomScreen` couple UI components directly to Matrix SDK types (`matrix.Room`, `matrix.Timeline`, `matrix.SyncUpdate`) or static mock data models (`MockChatPreview`, `MockMessage`).
4. **Inference**: To support local keypair identity, local SQLite storage, contact address modal, and relay settings, the UI and state management layer must be refactored to introduce domain abstractions (`ConversationEntity`, `MessageEntity`), dedicated BLoCs (`ChatListBloc`, `ChatRoomBloc`, `RelayBloc`), and repository interfaces (`IdentityRepository`, `LocalDatabaseRepository`).

## 3. Caveats
- No code in `lib/` was modified during this investigation (read-only mode strictly respected).
- Tests and runtime execution checks depend on the underlying Flutter environment.

## 4. Conclusion
The current UI and state management layer is highly coupled to `package:matrix` and the singleton `P2pNodeService`. Only `features/auth/` uses Flutter BLoC (`AuthBloc`). To support local keypair identity, local SQLite database storage, public key contact modals, and relay configuration, `lib/features/` requires architectural decoupling via domain entities, repositories, and new BLoCs (`ChatListBloc`, `ChatRoomBloc`, `SettingsBloc`).

## 5. Verification Method
1. Inspect detailed findings report:
   ```bash
   view_file /home/tommy/messaging/.agents/teamwork_preview_explorer_m0_2/analysis.md
   ```
2. Verify project files and line references:
   ```bash
   view_file /home/tommy/messaging/lib/main.dart
   view_file /home/tommy/messaging/lib/features/auth/presentation/bloc/auth_bloc.dart
   view_file /home/tommy/messaging/lib/features/chat/presentation/screens/chat_list_screen.dart
   view_file /home/tommy/messaging/lib/features/chat_room/presentation/screens/chat_room_screen.dart
   view_file /home/tommy/messaging/lib/features/settings/presentation/screens/settings_screen.dart
   ```
