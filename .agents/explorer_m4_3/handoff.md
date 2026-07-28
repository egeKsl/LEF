# Explorer 3 Analysis & Refactoring Plan: Chat Room & App Wiring (Milestone 4)

## Executive Summary
This document delivers a comprehensive architectural analysis and detailed refactoring plan for `lib/features/chat_room/` and `lib/main.dart` as part of Milestone 4 (UI Features & BLoCs Integration).

The analysis identifies critical architectural gaps in the current implementation—including direct repository instantiations inside UI widgets, lack of BLoC/Cubit state management in the chat room feature, missing network transport integration (`RelayTransportAdapter`), absence of payload encryption (`E2eCryptoService`), and incomplete global dependency injection in `lib/main.dart`.

---

## 1. Observation

### 1.1 Existing Codebase Inventory & State

#### A. Root Application & Initialization (`lib/main.dart`)
- **Current Content**:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final repository = LocalStorageRepository();
    final identityService = OfflineIdentityService();
    final identity = await repository.loadIdentity();
    final isLoggedIn = identity != null;
    final initialRoute = isLoggedIn ? AppRoutes.chatList : AppRoutes.auth;
    runApp(
      MultiProvider(
        providers: [
          Provider<LocalStorageRepository>.value(value: repository),
          Provider<IdentityService>.value(value: identityService),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              repository: repository,
              identityService: identityService,
            ),
          ),
        ],
        child: MyApp(initialRoute: initialRoute),
      ),
    );
  }
  ```
- **Observations & Gaps**:
  1. `RelayTransportAdapter` is **not instantiated, initialized, connected, or registered** in `MultiProvider`.
  2. `E2eCryptoService` (`PlaceholderE2eCryptoService`) is **not registered** in `MultiProvider`.
  3. No root-level lifecycle management for transport connections (e.g. connecting on app start, reconnecting on network state change).
  4. Route decision is performed once at startup (`isLoggedIn ? AppRoutes.chatList : AppRoutes.auth`), but app state transitions (e.g., identity creation/deletion) rely on imperative navigation.

#### B. Chat Room Screen (`lib/features/chat_room/presentation/screens/chat_room_screen.dart`)
- **Current Content**: Lines 23-58
  ```dart
  class _ChatRoomScreenState extends State<ChatRoomScreen> {
    final LocalStorageRepository _repository = LocalStorageRepository(); // VIOLATION!
    Conversation? _conversation;

    @override
    void initState() {
      super.initState();
      _loadConversation();
    }

    Future<void> _loadConversation() async {
      final conv = await _repository.getConversation(widget.conversationId);
      if (mounted) {
        setState(() { _conversation = conv; });
      }
    }

    Future<bool> _sendMessage(String message) async {
      if (_conversation == null) return false;
      final identity = await _repository.loadIdentity();
      final senderFp = identity?.fingerprint ?? 'local_user';
      final recipientFp = _conversation!.contact.fingerprint;

      final envelope = MessageEnvelope(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderFingerprint: senderFp,
        recipientFingerprint: recipientFp,
        payload: message.codeUnits, // RAW UNENCRYPTED BYTES!
        timestamp: DateTime.now().toUtc(),
        status: MessageDeliveryStatus.sent,
      );

      await _repository.saveEnvelope(envelope, conversationId: widget.conversationId);
      await _loadConversation();
      return true;
    }
  ```
- **Observations & Gaps**:
  1. **Layered Architecture Violation**: Line 23 directly instantiates `LocalStorageRepository` inside UI state instead of receiving it via dependency injection.
  2. **Missing BLoC/Cubit**: Lacks any BLoC or Cubit implementation. Presentation logic is managed via imperative `setState`.
  3. **No Payload Encryption**: Line 51 uses `payload: message.codeUnits` (raw character codes) rather than encrypting via `E2eCryptoService.encryptPayload`.
  4. **No Transport Adapter Calls**: Line 56 saves the message locally to SQLite, but **never invokes `RelayTransportAdapter.sendEnvelope()`**.
  5. **No Stream Listening**: Never listens to incoming messages from `RelayTransportAdapter.incomingEnvelopes`.

#### C. Message Stream Widget (`lib/features/chat_room/presentation/widgets/message_stream.dart`)
- **Current Content**: Lines 17-38
  ```dart
  class _MessageStreamState extends State<MessageStream> {
    final LocalStorageRepository _repository = LocalStorageRepository(); // VIOLATION!
    ...
    @override
    Widget build(BuildContext context) {
      return FutureBuilder<List<MessageEnvelope>>(
        future: _repository.getEnvelopesForConversation(widget.conversationId),
        builder: (context, snapshot) { ... }
      );
    }
  }
  ```
- **Observations & Gaps**:
  1. **Layered Architecture Violation**: Line 17 directly instantiates `LocalStorageRepository`.
  2. **Static Render via FutureBuilder**: Line 37 uses `FutureBuilder`, fetching envelopes once on widget build. Does not update in real-time when new incoming or outgoing messages arrive.
  3. **No Decryption**: Line 63 converts `envelope.payload` directly using `String.fromCharCodes(envelope.payload)`. Does not decrypt ciphertext envelopes using `E2eCryptoService`.

#### D. Aux UI Components (`lib/features/chat_room/presentation/widgets/`)
- `secure_input_bar.dart`: Well-structured UI input bar with ephemerality timer options (`0s`, `5s`, `1m`, `1h`). Delegates submission via `onMessageSubmitted` callback.
- `key_verification_dialog.dart`: Ephemeral key verification dialog displaying SAS emojis. Returns `bool?` (`true` for match, `false` for mismatch, `null` for abort).
- `custom_data_decoder_widget.dart`: Decodes visual hex data payloads (`CUSTOM_HEX_RAW://`) off-thread using `IsolateDecoderService`.

#### E. Core Services & Infrastructure (`lib/core/`)
- `LocalStorageRepository` (`lib/core/storage/local_storage_repository.dart`): Persistent storage for `LocalIdentity`, `ContactAddress`, `MessageEnvelope`, and `Conversation`. Provides `saveEnvelope`, `getEnvelopesForConversation`, `getConversation`, `saveConversation`.
- `RelayTransportAdapter` (`lib/core/transport/relay_transport_adapter.dart`): Relay transport implementation. Provides `connect()`, `disconnect()`, `sendEnvelope(envelope)`, `incomingEnvelopes` stream, and `simulateIncomingEnvelope()`.
- `PlaceholderE2eCryptoService` (`lib/core/messaging/e2e_crypto_service.dart`): E2EE payload encryption and decryption (`encryptPayload` and `decryptPayload`) using SHA-256 key streams and HMAC-SHA256 authentication.
- `OfflineIdentityService` (`lib/core/identity/identity_service.dart`): Offline client-side keypair generation and QR export/import.

---

## 2. Logic Chain & Refactoring Architecture

```
[UI Component: ChatRoomScreen]
       │
       ▼ (Dispatches Events)
[ChatRoomBloc / ChatRoomCubit]
       │
       ├───► [LocalStorageRepository] (Load history / Save envelopes)
       │
       ├───► [E2eCryptoService]       (Encrypt plaintext / Decrypt ciphertext)
       │
       └───► [RelayTransportAdapter]  (Send envelope / Listen to incomingEnvelopes stream)
```

### 2.1 Refactoring Plan for `ChatRoomBloc` (`lib/features/chat_room/presentation/bloc/`)

We will create a dedicated `ChatRoomBloc` handling all presentation logic, message encryption/decryption, database persistence, and real-time network stream subscriptions.

#### A. Events (`chat_room_event.dart`)
```dart
abstract class ChatRoomEvent {}

class LoadChatRoomEvent extends ChatRoomEvent {}

class SendChatMessageEvent extends ChatRoomEvent {
  final String messageText;
  final int ephemeralExpirySeconds;

  SendChatMessageEvent({
    required this.messageText,
    this.ephemeralExpirySeconds = 0,
  });
}

class IncomingMessageReceivedEvent extends ChatRoomEvent {
  final MessageEnvelope envelope;

  IncomingMessageReceivedEvent(this.envelope);
}

class KeyVerificationStatusChangedEvent extends ChatRoomEvent {
  final bool isVerified;

  KeyVerificationStatusChangedEvent(this.isVerified);
}
```

#### B. States (`chat_room_state.dart`)
```dart
abstract class ChatRoomState {}

class ChatRoomInitialState extends ChatRoomState {}

class ChatRoomLoadingState extends ChatRoomState {}

class ChatRoomLoadedState extends ChatRoomState {
  final Conversation conversation;
  final LocalIdentity localIdentity;
  final List<MessageDisplayModel> messages;
  final TransportConnectionState connectionState;
  final bool isSending;
  final bool isSessionTrusted;

  ChatRoomLoadedState({
    required this.conversation,
    required this.localIdentity,
    required this.messages,
    required this.connectionState,
    this.isSending = false,
    this.isSessionTrusted = false,
  });

  ChatRoomLoadedState copyWith({
    Conversation? conversation,
    LocalIdentity? localIdentity,
    List<MessageDisplayModel>? messages,
    TransportConnectionState? connectionState,
    bool? isSending,
    bool? isSessionTrusted,
  }) {
    return ChatRoomLoadedState(
      conversation: conversation ?? this.conversation,
      localIdentity: localIdentity ?? this.localIdentity,
      messages: messages ?? this.messages,
      connectionState: connectionState ?? this.connectionState,
      isSending: isSending ?? this.isSending,
      isSessionTrusted: isSessionTrusted ?? this.isSessionTrusted,
    );
  }
}

class ChatRoomErrorState extends ChatRoomState {
  final String errorMessage;

  ChatRoomErrorState(this.errorMessage);
}
```

#### C. Message Display Wrapper Model (`message_display_model.dart`)
To decouple UI rendering from raw byte manipulation, we define a lightweight display model containing the decrypted content cache:
```dart
class MessageDisplayModel {
  final MessageEnvelope envelope;
  final String textContent;
  final bool isFromMe;
  final bool isDecryptionFailed;

  MessageDisplayModel({
    required this.envelope,
    required this.textContent,
    required this.isFromMe,
    this.isDecryptionFailed = false,
  });
}
```

#### D. `ChatRoomBloc` Implementation Logic (`chat_room_bloc.dart`)
```dart
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final LocalStorageRepository repository;
  final TransportAdapter transportAdapter;
  final E2eCryptoService cryptoService;
  final String conversationId;

  StreamSubscription<MessageEnvelope>? _incomingSubscription;
  StreamSubscription<TransportConnectionState>? _connectionSubscription;

  ChatRoomBloc({
    required this.repository,
    required this.transportAdapter,
    required this.cryptoService,
    required this.conversationId,
  }) : super(ChatRoomInitialState()) {
    on<LoadChatRoomEvent>(_onLoadChatRoom);
    on<SendChatMessageEvent>(_onSendChatMessage);
    on<IncomingMessageReceivedEvent>(_onIncomingMessageReceived);
    on<KeyVerificationStatusChangedEvent>(_onKeyVerificationStatusChanged);
  }

  Future<void> _onLoadChatRoom(LoadChatRoomEvent event, Emitter<ChatRoomState> emit) async {
    emit(ChatRoomLoadingState());
    try {
      final conversation = await repository.getConversation(conversationId);
      final identity = await repository.loadIdentity();

      if (conversation == null || identity == null) {
        emit(ChatRoomErrorState("CONVERSATION_OR_IDENTITY_NOT_FOUND"));
        return;
      }

      // Mark unread count as read
      if (conversation.unreadCount > 0) {
        final readConv = conversation.markAsRead();
        await repository.saveConversation(readConv);
      }

      // Decrypt message history payloads
      final displayMessages = <MessageDisplayModel>[];
      for (final env in conversation.messages) {
        final displayModel = await _processEnvelopeToDisplay(env, identity, conversation.contact);
        displayMessages.add(displayModel);
      }

      // Subscribe to transport incoming stream
      await _incomingSubscription?.cancel();
      _incomingSubscription = transportAdapter.incomingEnvelopes.listen((envelope) {
        if (envelope.senderFingerprint == conversation.contact.fingerprint ||
            envelope.recipientFingerprint == identity.fingerprint) {
          add(IncomingMessageReceivedEvent(envelope));
        }
      });

      emit(ChatRoomLoadedState(
        conversation: conversation,
        localIdentity: identity,
        messages: displayMessages,
        connectionState: transportAdapter.state,
      ));
    } catch (e) {
      emit(ChatRoomErrorState("LOAD_FAILED: ${e.toString()}"));
    }
  }

  Future<void> _onSendChatMessage(SendChatMessageEvent event, Emitter<ChatRoomState> emit) async {
    final currentState = state;
    if (currentState is! ChatRoomLoadedState) return;

    emit(currentState.copyWith(isSending: true));

    try {
      final identity = currentState.localIdentity;
      final contact = currentState.conversation.contact;

      // 1. Encrypt message text using E2E Crypto Service
      final plaintextBytes = utf8.encode(event.messageText);
      final ciphertextPayload = await cryptoService.encryptPayload(
        plaintext: plaintextBytes,
        recipientPublicKey: contact.fingerprint,
        senderSecretKey: identity.secretKey,
      );

      // 2. Construct MessageEnvelope
      final envelope = MessageEnvelope(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        senderFingerprint: identity.fingerprint,
        recipientFingerprint: contact.fingerprint,
        payload: ciphertextPayload,
        timestamp: DateTime.now().toUtc(),
        status: MessageDeliveryStatus.pending,
      );

      // 3. Save envelope locally
      await repository.saveEnvelope(envelope, conversationId: conversationId);

      // 4. Send via Transport Adapter
      final isSent = await transportAdapter.sendEnvelope(envelope);
      final finalStatus = isSent ? MessageDeliveryStatus.sent : MessageDeliveryStatus.failed;
      final updatedEnvelope = envelope.copyWith(status: finalStatus);

      // Update in storage if status changed
      if (finalStatus != MessageDeliveryStatus.pending) {
        await repository.saveEnvelope(updatedEnvelope, conversationId: conversationId);
      }

      // 5. Create display model and update state
      final displayModel = MessageDisplayModel(
        envelope: updatedEnvelope,
        textContent: event.messageText,
        isFromMe: true,
      );

      final updatedMessages = List<MessageDisplayModel>.from(currentState.messages)..add(displayModel);
      final updatedConv = currentState.conversation.copyWith(
        messages: updatedMessages.map((m) => m.envelope).toList(),
        lastUpdated: updatedEnvelope.timestamp,
      );

      emit(currentState.copyWith(
        conversation: updatedConv,
        messages: updatedMessages,
        isSending: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSending: false));
    }
  }

  Future<void> _onIncomingMessageReceived(IncomingMessageReceivedEvent event, Emitter<ChatRoomState> emit) async {
    final currentState = state;
    if (currentState is! ChatRoomLoadedState) return;

    // Check if envelope is already present to prevent duplicate processing
    if (currentState.messages.any((m) => m.envelope.id == event.envelope.id)) return;

    // Save envelope locally
    await repository.saveEnvelope(event.envelope, conversationId: conversationId);

    // Process & decrypt incoming envelope
    final displayModel = await _processEnvelopeToDisplay(
      event.envelope,
      currentState.localIdentity,
      currentState.conversation.contact,
    );

    final updatedMessages = List<MessageDisplayModel>.from(currentState.messages)..add(displayModel);
    final updatedConv = currentState.conversation.copyWith(
      messages: updatedMessages.map((m) => m.envelope).toList(),
      lastUpdated: event.envelope.timestamp,
    );

    emit(currentState.copyWith(
      conversation: updatedConv,
      messages: updatedMessages,
    ));
  }

  Future<MessageDisplayModel> _processEnvelopeToDisplay(
    MessageEnvelope envelope,
    LocalIdentity identity,
    ContactAddress contact,
  ) async {
    final isMe = envelope.senderFingerprint == identity.fingerprint;
    String textContent;
    bool isFailed = false;

    try {
      if (isMe) {
        // Decrypt sent message or try UTF-8 fallback
        final decrypted = await cryptoService.decryptPayload(
          ciphertext: envelope.payload,
          senderPublicKey: contact.fingerprint,
          recipientSecretKey: identity.secretKey,
        );
        textContent = utf8.decode(decrypted);
      } else {
        // Decrypt incoming message using sender's public key & recipient secret key
        final decrypted = await cryptoService.decryptPayload(
          ciphertext: envelope.payload,
          senderPublicKey: envelope.senderFingerprint,
          recipientSecretKey: identity.secretKey,
        );
        textContent = utf8.decode(decrypted);
      }
    } catch (_) {
      // Fallback for unencrypted legacy or raw text payloads
      try {
        textContent = utf8.decode(envelope.payload);
      } catch (e) {
        textContent = "DECRYPTION_FAILED // MALFORMED_PAYLOAD";
        isFailed = true;
      }
    }

    return MessageDisplayModel(
      envelope: envelope,
      textContent: textContent,
      isFromMe: isMe,
      isDecryptionFailed: isFailed,
    );
  }

  @override
  Future<void> close() {
    _incomingSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
```

---

### 2.2 Refactoring Plan for `ChatRoomScreen` & `MessageStream`

#### A. Refactored `ChatRoomScreen` (`lib/features/chat_room/presentation/screens/chat_room_screen.dart`)
- Eliminates direct `LocalStorageRepository` instantiation.
- Receives dependencies via `BlocBuilder<ChatRoomBloc, ChatRoomState>`.
- Displays real-time connection status in AppBar (`E2EE_ACTIVE_ENCRYPTED_CHANNEL` or `RECONNECTING`).
- Dispatches `SendChatMessageEvent` when `SecureInputBar` triggers message submission.

```dart
class ChatRoomScreen extends StatelessWidget {
  final String conversationId;

  const ChatRoomScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      listener: (context, state) {
        if (state is ChatRoomErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1A0505),
              content: Text(state.errorMessage, style: const TextStyle(color: SecureColors.panicRed)),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ChatRoomLoadingState || state is ChatRoomInitialState) {
          return const Scaffold(
            backgroundColor: SecureColors.background,
            body: Center(
              child: CircularProgressIndicator(color: SecureColors.cyberBlue, strokeWidth: 1.5),
            ),
          );
        }

        if (state is! ChatRoomLoadedState) {
          return const Scaffold(
            backgroundColor: SecureColors.background,
            body: Center(child: Text("FAILED_TO_LOAD_CHAT_ROOM", style: TextStyle(color: SecureColors.panicRed))),
          );
        }

        final roomName = state.conversation.contact.displayName;

        return Scaffold(
          backgroundColor: SecureColors.background,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: SecureColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: SecureColors.textPrimary, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(color: SecureColors.textPrimary, fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: state.connectionState == TransportConnectionState.connected
                            ? SecureColors.cryptoGreen
                            : SecureColors.panicRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.connectionState == TransportConnectionState.connected
                          ? 'E2EE_ACTIVE_ENCRYPTED_CHANNEL'
                          : 'TRANSPORT_DISCONNECTED',
                      style: TextStyle(
                        color: state.connectionState == TransportConnectionState.connected
                            ? SecureColors.cryptoGreen
                            : SecureColors.panicRed,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: SecureColors.cyberBlue, size: 18),
                onPressed: () async {
                  final result = await KeyVerificationDialog.show(
                    context,
                    remoteUserId: state.conversation.contact.fingerprint,
                  );
                  if (result != null && context.mounted) {
                    context.read<ChatRoomBloc>().add(KeyVerificationStatusChangedEvent(result));
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: MessageStream(messages: state.messages),
              ),
              SecureInputBar(
                onMessageSubmitted: (message, expiry) async {
                  context.read<ChatRoomBloc>().add(
                    SendChatMessageEvent(messageText: message, ephemeralExpirySeconds: expiry),
                  );
                  return true;
                },
                onAttachmentTriggered: () {
                  // Attachment extraction pipeline hook
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

#### B. Refactored `MessageStream` (`lib/features/chat_room/presentation/widgets/message_stream.dart`)
- Converted to a Stateless presentation component.
- Receives `List<MessageDisplayModel>` directly from `ChatRoomLoadedState`.
- Renders messages instantaneously with no `FutureBuilder` or DB querying.

```dart
class MessageStream extends StatelessWidget {
  final List<MessageDisplayModel> messages;

  const MessageStream({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final reversedMessages = messages.reversed.toList();
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return ListView.builder(
      itemCount: reversedMessages.length,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemBuilder: (context, index) {
        final item = reversedMessages[index];
        final body = item.textContent;
        final isMe = item.isFromMe;
        final isCustomEncodedVisual = body.startsWith('CUSTOM_HEX_RAW://');

        final timeStr = item.envelope.timestamp.toIso8601String().length >= 16
            ? item.envelope.timestamp.toIso8601String().substring(11, 16)
            : '--:--';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              cross: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  decoration: BoxDecoration(
                    color: isMe ? SecureColors.surfaceDarkSlate : SecureColors.surfaceCharcoal,
                    borderRadius: BorderRadius.circular(4.0),
                    border: item.isDecryptionFailed
                        ? Border.all(color: SecureColors.panicRed, width: 0.5)
                        : null,
                  ),
                  child: isCustomEncodedVisual
                      ? CustomDataDecoderWidget(
                          rawEncodedPayload: body.replaceFirst('CUSTOM_HEX_RAW://', ''),
                        )
                      : Text(
                          body,
                          style: TextStyle(
                            color: item.isDecryptionFailed ? SecureColors.panicRed : SecureColors.textPrimary,
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(color: SecureColors.textSecondary, fontSize: 9.0),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        item.envelope.status == MessageDeliveryStatus.sent
                            ? Icons.done_all
                            : Icons.access_time,
                        size: 10,
                        color: SecureColors.cyberBlue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 3. Global App Initialization & Wiring (`lib/main.dart`)

### 3.1 Refactored `lib/main.dart`
- Initializes `LocalStorageRepository`, `OfflineIdentityService`, `RelayTransportAdapter`, and `PlaceholderE2eCryptoService`.
- Connects `RelayTransportAdapter` during app launch.
- Registers all core infrastructure singletons cleanly in `MultiProvider` at the top of the widget tree.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'config/routes/app_routes.dart';
import 'core/identity/identity_service.dart';
import 'core/messaging/e2e_crypto_service.dart';
import 'core/storage/local_storage_repository.dart';
import 'core/transport/relay_transport_adapter.dart';
import 'core/transport/transport_adapter.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat_room/presentation/bloc/chat_room_bloc.dart';
import 'theme/secure_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Core Repositories and Services
  final repository = LocalStorageRepository();
  final identityService = OfflineIdentityService();
  final transportAdapter = RelayTransportAdapter(relayUrl: 'wss://relay.example.com');
  final cryptoService = PlaceholderE2eCryptoService();

  // 2. Connect transport network layer
  await transportAdapter.connect();

  // 3. Evaluate identity state for initial route determination
  final identity = await repository.loadIdentity();
  final isLoggedIn = identity != null;
  final initialRoute = isLoggedIn ? AppRoutes.chatList : AppRoutes.auth;

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageRepository>.value(value: repository),
        Provider<IdentityService>.value(value: identityService),
        Provider<TransportAdapter>.value(value: transportAdapter),
        Provider<E2eCryptoService>.value(value: cryptoService),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            repository: repository,
            identityService: identityService,
          ),
        ),
      ],
      child: MyApp(
        initialRoute: initialRoute,
        repository: repository,
        transportAdapter: transportAdapter,
        cryptoService: cryptoService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialRoute,
    required this.repository,
    required this.transportAdapter,
    required this.cryptoService,
  });

  final String initialRoute;
  final LocalStorageRepository repository;
  final TransportAdapter transportAdapter;
  final E2eCryptoService cryptoService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decentralized Secure Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SecureColors.background,
        canvasColor: SecureColors.background,
        colorScheme: const ColorScheme.dark(
          surface: SecureColors.background,
          primary: SecureColors.textPrimary,
          secondary: SecureColors.cyberBlue,
          error: SecureColors.panicRed,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: SecureColors.cyberBlue,
          selectionColor: SecureColors.surfaceDarkSlate,
          selectionHandleColor: SecureColors.cyberBlue,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: SecureColors.textSecondary, fontFamily: 'Inter'),
        ),
      ),
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.chatRoom) {
          final conversationId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => BlocProvider<ChatRoomBloc>(
              create: (_) => ChatRoomBloc(
                repository: repository,
                transportAdapter: transportAdapter,
                cryptoService: cryptoService,
                conversationId: conversationId,
              )..add(LoadChatRoomEvent()),
              child: ChatRoomScreen(conversationId: conversationId),
            ),
          );
        }
        return null;
      },
      routes: AppRoutes.routes,
    );
  }
}
```

### 3.2 AppRoutes Dynamic Navigation Mapping (`lib/config/routes/app_routes.dart`)
Update `AppRoutes` to include constant route definition for `/chat-room`:
```dart
class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        auth: (context) => const AuthScreen(),
        chatList: (context) => const ChatListScreen(),
        settings: (context) => const SettingsScreen(),
      };
}
```

---

## 4. Verification of Layered Architecture Compliance

| Layer | Component | Permitted Access | Prohibited Access | Status Post-Refactor |
|---|---|---|---|---|
| **Presentation** | `ChatRoomScreen`, `MessageStream` | BLoCs (`ChatRoomBloc`), View States | Direct DB / Storage instantiations (`LocalStorageRepository()`) | **COMPLIANT** |
| **Presentation / State** | `ChatRoomBloc` | Repositories, Transport Adapters, Crypto Services | Direct Flutter UI elements (`BuildContext`, `Widget`) | **COMPLIANT** |
| **Core / Domain** | `MessageEnvelope`, `Conversation`, `ContactAddress` | Pure Dart logic | Flutter UI packages, Matrix `@user:server` syntax | **COMPLIANT** |
| **Data Infrastructure** | `LocalStorageRepository`, `RelayTransportAdapter`, `IsolateDecoderService` | Database (`sqflite`), WebSockets, Isolates | Presentation widgets, UI context | **COMPLIANT** |

---

## 5. Caveats & Edge-Case Handling

1. **Simulated Relay vs Real Socket Transport**:
   - `RelayTransportAdapter` provides `simulateIncomingEnvelope()`. The BLoC architecture relies strictly on the abstract `TransportAdapter` interface, allowing full seamless migration to real WebSocket or WebRTC connections without modifying BLoC or UI logic.
2. **Dual Payload Format Support**:
   - `ChatRoomBloc` attempts `E2eCryptoService.decryptPayload` first. If decryption fails (e.g. legacy plain text payloads or test harness payloads), it gracefully falls back to UTF-8 decoding.
3. **Isolate Payload Offloading**:
   - `CUSTOM_HEX_RAW://` payloads continue to use `IsolateDecoderService.decodeCustomVisualData` in `CustomDataDecoderWidget`, ensuring heavy visual decode tasks do not block the UI thread.

---

## 6. Verification Method

To independently verify the refactored Chat Room feature and App initialization:

1. **Run Static Analysis**:
   ```bash
   dart analyze
   ```
   *Condition for success*: 0 errors, 0 warnings.

2. **Execute Core & Feature Unit Tests**:
   ```bash
   flutter test test/core/storage/local_storage_repository_test.dart
   flutter test test/core/transport/relay_transport_adapter_test.dart
   ```

3. **Validate ChatRoomBloc Integration Harness**:
   Create `test/features/chat_room/presentation/bloc/chat_room_bloc_test.dart` to verify:
   - History loading from repository
   - E2EE payload encryption and transmission through `sendEnvelope`
   - Real-time handling of `incomingEnvelopes` stream events
