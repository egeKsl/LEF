# Milestone 4 Handoff Report: UI Features & BLoCs Integration (Chat List & New Chat Modal)

**Explorer**: Explorer 2 (`explorer_m4_2`)  
**Working Directory**: `/home/tommy/messaging/.agents/explorer_m4_2`  
**Target Subsystems**: `lib/features/chat/` (`chat_list_screen.dart`, `encrypted_chat_tile.dart`, `new_chat_modal.dart`, `status_app_bar.dart`)  

---

## 1. Observation

### 1.1 Direct Repository / Storage Violations in UI Components
- **File**: `lib/features/chat/presentation/screens/chat_list_screen.dart`
  - **Line 45**: `final LocalStorageRepository _repository = LocalStorageRepository();`
  - **Lines 104-129**: Uses a `FutureBuilder<List<Conversation>>` targeting `_repository.getConversations()`.
  - **Lines 53, 142**: Invokes `setState(() {})` inside route callbacks (`Navigator.push(...).then((_) => setState(() {}))`) to manually trigger data reload.
  - **Violation**: Direct instantiation and invocation of data repository (`LocalStorageRepository`) inside a UI `StatefulWidget`. Violates `UI -> Domain/BLoC -> Data` architectural boundaries.
- **File**: `lib/features/chat/presentation/widgets/new_chat_modal.dart`
  - **Line 32**: `final LocalStorageRepository _repository = LocalStorageRepository();`
  - **Lines 112, 122**: Directly calls `_repository.saveContact(contact)` and `_repository.saveConversation(newConv)`.
  - **Violation**: Data persistence logic embedded directly inside UI modal widget.

### 1.2 Lack of Real-Time Event & Transport Stream Handling
- `ChatListScreen` is currently static: it only reads local SQLite storage on build / manual `setState()`.
- It does not listen to `TransportAdapter.incomingEnvelopes` (stream of `MessageEnvelope`) to update the conversation list or increment unread counts when a new message arrives from a remote peer.
- It does not listen to `TransportAdapter.connectionState` to update connection status indicators in real-time.

### 1.3 Missing Relay URL Hint Input & Legacy Wording
- **File**: `lib/features/chat/presentation/widgets/new_chat_modal.dart`
  - Modal currently has only one text input field (`AuthTextField`) for contact public key fingerprint (`_contactIdController`).
  - It lacks a second text input field for an optional **Relay Server URL Hint** (e.g. `wss://relay.example.com`).
- **File**: `lib/features/chat/presentation/widgets/status_app_bar.dart`
  - **Line 54**: Header contains legacy string `"MATRIX PROTOCOL NODE"`. Must be updated to `"DECENTRALIZED NODE"` or `"RELAY NODE"`.
  - Default status is hardcoded to `"P2P MESH ACTIVE"`.

### 1.4 Formatting & Validation Capabilities in Core Models
- `ContactAddress.isValidFingerprint(String fingerprint)` in `lib/core/addressing/contact_address.dart` validates Base58/Base64 key strings and strictly rejects strings containing Matrix user ID delimiters (`@` or `:`).
- `LocalStorageRepository` (`lib/core/storage/local_storage_repository.dart`) provides:
  - `getConversations()`: returns `List<Conversation>` ordered by `lastUpdated DESC`.
  - `saveContact(ContactAddress contact)`: persists peer address.
  - `saveConversation(Conversation conversation)`: persists conversation entity.
  - `getConversation(String id)`: loads conversation header, contact, and message history.

---

## 2. Logic Chain

1. **Clean Architecture Enforcement**:
   - To comply with `UI -> Domain/BLoC -> Data`, all direct references to `LocalStorageRepository` and `TransportAdapter` must be removed from `chat_list_screen.dart` and `new_chat_modal.dart`.
   - A dedicated `ChatListBloc` must be introduced under `lib/features/chat/presentation/bloc/chat_list_bloc.dart`.
   - A dedicated `NewChatCubit` must be introduced under `lib/features/chat/presentation/bloc/new_chat_cubit.dart`.

2. **Real-Time Data Flow in `ChatListBloc`**:
   - `ChatListBloc` will accept `LocalStorageRepository` and `TransportAdapter` via constructor.
   - On initialization (`LoadChatListRequested`), it fetches all stored conversations from `LocalStorageRepository`.
   - It subscribes to `TransportAdapter.incomingEnvelopes`. When an envelope arrives:
     - It finds or constructs the corresponding `Conversation` for `envelope.senderFingerprint`.
     - Appends the message and increments unread count (`conv.addMessage(envelope, isIncoming: true)`).
     - Persists updated conversation to `LocalStorageRepository`.
     - Emits `ChatListLoaded` state with updated conversation list and unread counts.
   - It subscribes to `TransportAdapter.connectionState`. When connection state updates (`connected`, `connecting`, `disconnected`), it emits updated `ChatListLoaded` state to refresh `StatusAppBar`.

3. **Validation and Contact Creation in `NewChatCubit`**:
   - `NewChatCubit` handles contact & conversation creation asynchronously.
   - Accepts `fingerprint` and optional `relayUrlHint`.
   - Validates fingerprint via `ContactAddress.isValidFingerprint(fingerprint)`. If invalid or contains `@`/`:`, returns error state.
   - Validates `relayUrlHint` if provided.
   - Constructs `ContactAddress(fingerprint: fingerprint, displayName: ..., relayUrlHint: relayUrlHint)`.
   - Saves contact to `LocalStorageRepository` and creates initial `Conversation` entity.
   - Emits `NewChatSuccess(conversationId)` for UI navigation.

4. **UI Refactoring Plan**:
   - `ChatListScreen`: uses `BlocBuilder<ChatListBloc, ChatListState>` to render `EncryptedChatTile` items and `StatusAppBar` status.
   - `NewChatModal`: provides two text inputs (Fingerprint + optional Relay URL Hint), scanner integration, uses `BlocConsumer<NewChatCubit, NewChatState>` to dispatch actions and navigate on success.

---

## 3. Caveats

- **Chat Room Navigation & Deep Messaging**: `ChatRoomScreen` and in-room messaging streams are handled by Explorer 3 / Implementer 3 (`explorer_m4_3`). `ChatListScreen` only needs to trigger navigation with `conversationId`.
- **Global Dependency Injection**: BLoCs should be instantiated at `main.dart` or provided via `BlocProvider`. `ChatListBloc` requires a `TransportAdapter` instance (e.g. `RelayTransportAdapter`) injected at app level.
- **Headless Camera Testing**: `MobileScanner` requires camera permissions on real devices/emulators. In unit/widget tests, `NewChatCubit` logic should be tested directly without triggering `MobileScanner` viewfinders.

---

## 4. Conclusion

The refactoring plan for Chat List & New Chat Modal establishes full real-time capabilities, eliminates legacy Matrix structures, adds optional relay URL hint support for contacts, and enforces strict Clean Architecture layering.

### Proposed Code Implementations

#### A. `lib/features/chat/presentation/bloc/chat_list_bloc.dart`

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/addressing/contact_address.dart';
import '../../../../core/messaging/conversation.dart';
import '../../../../core/messaging/message_envelope.dart';
import '../../../../core/storage/local_storage_repository.dart';
import '../../../../core/transport/transport_adapter.dart';

// --- Events ---
abstract class ChatListEvent {}

class LoadChatListRequested extends ChatListEvent {}

class IncomingEnvelopeReceived extends ChatListEvent {
  final MessageEnvelope envelope;
  IncomingEnvelopeReceived(this.envelope);
}

class TransportStateChanged extends ChatListEvent {
  final TransportConnectionState connectionState;
  TransportStateChanged(this.connectionState);
}

class MarkConversationReadRequested extends ChatListEvent {
  final String conversationId;
  MarkConversationReadRequested(this.conversationId);
}

class RefreshChatListRequested extends ChatListEvent {}

// --- States ---
abstract class ChatListState {}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<Conversation> conversations;
  final TransportConnectionState connectionState;

  ChatListLoaded({
    required this.conversations,
    required this.connectionState,
  });

  int get totalUnreadCount => conversations.fold(0, (sum, c) => sum + c.unreadCount);
}

class ChatListError extends ChatListState {
  final String message;
  ChatListError(this.message);
}

// --- Bloc ---
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final LocalStorageRepository _repository;
  final TransportAdapter? _transportAdapter;
  StreamSubscription<MessageEnvelope>? _envelopeSub;
  StreamSubscription<TransportConnectionState>? _transportSub;

  ChatListBloc({
    LocalStorageRepository? repository,
    TransportAdapter? transportAdapter,
  })  : _repository = repository ?? LocalStorageRepository(),
        _transportAdapter = transportAdapter,
        super(ChatListInitial()) {
    on<LoadChatListRequested>(_onLoadChatListRequested);
    on<IncomingEnvelopeReceived>(_onIncomingEnvelopeReceived);
    on<TransportStateChanged>(_onTransportStateChanged);
    on<MarkConversationReadRequested>(_onMarkConversationReadRequested);
    on<RefreshChatListRequested>(_onRefreshChatListRequested);

    _listenToTransport();
  }

  void _listenToTransport() {
    if (_transportAdapter != null) {
      _envelopeSub = _transportAdapter!.incomingEnvelopes.listen((envelope) {
        add(IncomingEnvelopeReceived(envelope));
      });
      _transportSub = _transportAdapter!.connectionState.listen((state) {
        add(TransportStateChanged(state));
      });
    }
  }

  Future<void> _onLoadChatListRequested(
    LoadChatListRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(ChatListLoading());
    try {
      final conversations = await _repository.getConversations();
      final connState = _transportAdapter?.state ?? TransportConnectionState.disconnected;
      emit(ChatListLoaded(
        conversations: conversations,
        connectionState: connState,
      ));
    } catch (e) {
      emit(ChatListError("FAILED TO LOAD CONVERSATIONS // $e"));
    }
  }

  Future<void> _onIncomingEnvelopeReceived(
    IncomingEnvelopeReceived event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final envelope = event.envelope;
      final senderFp = envelope.senderFingerprint;
      final convId = 'conv_$senderFp';

      Conversation? conv = await _repository.getConversation(convId);
      if (conv == null) {
        ContactAddress? contact = await _repository.getContact(senderFp);
        contact ??= ContactAddress(
          fingerprint: senderFp,
          displayName: senderFp.length >= 6 ? 'Contact ${senderFp.substring(0, 6)}' : senderFp,
        );
        conv = Conversation(
          id: convId,
          contact: contact,
          messages: [envelope],
          unreadCount: 1,
          lastUpdated: envelope.timestamp,
        );
      } else {
        conv = conv.addMessage(envelope, isIncoming: true);
      }

      await _repository.saveConversation(conv);

      final updatedList = await _repository.getConversations();
      final connState = _transportAdapter?.state ?? TransportConnectionState.disconnected;
      emit(ChatListLoaded(
        conversations: updatedList,
        connectionState: connState,
      ));
    } catch (_) {}
  }

  Future<void> _onTransportStateChanged(
    TransportStateChanged event,
    Emitter<ChatListState> emit,
  ) async {
    if (state is ChatListLoaded) {
      final current = state as ChatListLoaded;
      emit(ChatListLoaded(
        conversations: current.conversations,
        connectionState: event.connectionState,
      ));
    }
  }

  Future<void> _onMarkConversationReadRequested(
    MarkConversationReadRequested event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final conv = await _repository.getConversation(event.conversationId);
      if (conv != null && conv.unreadCount > 0) {
        final updated = conv.markAsRead();
        await _repository.saveConversation(updated);
        add(RefreshChatListRequested());
      }
    } catch (_) {}
  }

  Future<void> _onRefreshChatListRequested(
    RefreshChatListRequested event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final conversations = await _repository.getConversations();
      final connState = _transportAdapter?.state ?? TransportConnectionState.disconnected;
      emit(ChatListLoaded(
        conversations: conversations,
        connectionState: connState,
      ));
    } catch (e) {
      emit(ChatListError("REFRESH FAILED // $e"));
    }
  }

  @override
  Future<void> close() {
    _envelopeSub?.cancel();
    _transportSub?.cancel();
    return super.close();
  }
}
```

#### B. `lib/features/chat/presentation/bloc/new_chat_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/addressing/contact_address.dart';
import '../../../../core/messaging/conversation.dart';
import '../../../../core/storage/local_storage_repository.dart';

abstract class NewChatState {}

class NewChatInitial extends NewChatState {}

class NewChatSubmitting extends NewChatState {}

class NewChatSuccess extends NewChatState {
  final String conversationId;
  NewChatSuccess(this.conversationId);
}

class NewChatFailure extends NewChatState {
  final String message;
  NewChatFailure(this.message);
}

class NewChatCubit extends Cubit<NewChatState> {
  final LocalStorageRepository _repository;

  NewChatCubit({LocalStorageRepository? repository})
      : _repository = repository ?? LocalStorageRepository(),
        super(NewChatInitial());

  Future<void> initiateNewChat({
    required String fingerprint,
    String? relayUrlHint,
  }) async {
    emit(NewChatSubmitting());
    final trimmedFp = fingerprint.trim();
    final trimmedRelay = relayUrlHint?.trim();

    if (!ContactAddress.isValidFingerprint(trimmedFp)) {
      emit(NewChatFailure("INVALID_FINGERPRINT_FORMAT // Matrix user IDs & invalid keys prohibited"));
      return;
    }

    try {
      ContactAddress contact;
      try {
        contact = ContactAddress.parse(trimmedFp);
        if (trimmedRelay != null && trimmedRelay.isNotEmpty) {
          contact = contact.copyWith(relayUrlHint: trimmedRelay);
        }
      } catch (_) {
        contact = ContactAddress(
          fingerprint: trimmedFp,
          displayName: trimmedFp.length >= 6 ? 'Contact ${trimmedFp.substring(0, 6)}' : trimmedFp,
          relayUrlHint: (trimmedRelay != null && trimmedRelay.isNotEmpty) ? trimmedRelay : null,
        );
      }

      final convId = 'conv_${contact.fingerprint}';
      await _repository.saveContact(contact);

      final existingConv = await _repository.getConversation(convId);
      if (existingConv == null) {
        final newConv = Conversation(
          id: convId,
          contact: contact,
          messages: [],
          lastUpdated: DateTime.now().toUtc(),
        );
        await _repository.saveConversation(newConv);
      }

      emit(NewChatSuccess(convId));
    } catch (e) {
      emit(NewChatFailure("HANDSHAKE_FAILED // ${e.toString()}"));
    }
  }
}
```

#### C. Refactored `lib/features/chat/presentation/screens/chat_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/messaging/conversation.dart';
import '../../../../theme/secure_colors.dart';
import '../../../chat_room/presentation/screens/chat_room_screen.dart';
import '../bloc/chat_list_bloc.dart';
import '../widgets/encrypted_chat_tile.dart';
import '../widgets/new_chat_modal.dart';
import '../widgets/status_app_bar.dart';

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '--:--';
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatListBloc>().add(LoadChatListRequested());
  }

  void _openChatRoom(BuildContext context, Conversation conversation) {
    context.read<ChatListBloc>().add(MarkConversationReadRequested(conversation.id));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(conversationId: conversation.id),
      ),
    ).then((_) {
      if (mounted) {
        context.read<ChatListBloc>().add(RefreshChatListRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const fabClearance = 56.0 + 22.0 + 20.0;

    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) {
        String syncStatusText = "DISCONNECTED";
        if (state is ChatListLoaded) {
          syncStatusText = state.connectionState.name.toUpperCase();
        }

        return Scaffold(
          backgroundColor: SecureColors.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(StatusAppBar.height(context)),
            child: StatusAppBar(
              syncStatus: syncStatusText,
              onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ),
          body: SafeArea(
            top: false,
            child: _buildBody(context, state, bottomInset, fabClearance),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: SecureColors.textPrimary,
            foregroundColor: SecureColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            onPressed: () async {
              await NewChatModal.show(context);
              if (context.mounted) {
                context.read<ChatListBloc>().add(RefreshChatListRequested());
              }
            },
            child: const Icon(Icons.add, size: 24.0),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChatListState state,
    double bottomInset,
    double fabClearance,
  ) {
    if (state is ChatListLoading || state is ChatListInitial) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
        ),
      );
    }

    if (state is ChatListError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: SecureColors.panicRed, fontFamily: 'Inter'),
        ),
      );
    }

    if (state is ChatListLoaded) {
      if (state.conversations.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset + fabClearance),
            child: const Text(
              "NO ACTIVE CRYPTO-CHANNELS\n// TAP FAB TO INITIALIZE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SecureColors.textSecondary,
                fontFamily: 'Inter',
                fontSize: 11.0,
                letterSpacing: 1.0,
                height: 1.6,
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.only(bottom: bottomInset + fabClearance),
        itemCount: state.conversations.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final conv = state.conversations[index];
          final lastMsg = conv.messages.isNotEmpty
              ? (conv.messages.last.payload.isNotEmpty
                  ? String.fromCharCodes(conv.messages.last.payload)
                  : "ENCRYPTED_MESSAGE")
              : "EMPTY_CHANNEL_LOG";

          return EncryptedChatTile(
            roomName: conv.contact.displayName,
            lastMessage: lastMsg,
            timestamp: _formatTimestamp(conv.lastUpdated),
            unreadCount: conv.unreadCount,
            isEncrypted: true,
            onTap: () => _openChatRoom(context, conv),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
```

#### D. Refactored `lib/features/chat/presentation/widgets/new_chat_modal.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/addressing/contact_address.dart';
import '../../../../theme/secure_colors.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../chat_room/presentation/screens/chat_room_screen.dart';
import '../bloc/new_chat_cubit.dart';

class NewChatModal extends StatefulWidget {
  const NewChatModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SecureColors.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (_) => BlocProvider(
        create: (context) => NewChatCubit(),
        child: const NewChatModal(),
      ),
    );
  }

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> {
  late final TextEditingController _contactIdController;
  late final TextEditingController _relayUrlHintController;
  MobileScannerController? _scannerController;
  bool? _hasPermission;
  String? _errorMessage;
  String? _detectedId;
  bool _isValidFormat = false;

  @override
  void initState() {
    super.initState();
    _contactIdController = TextEditingController();
    _relayUrlHintController = TextEditingController();
    _contactIdController.addListener(_onTextChanged);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _contactIdController.removeListener(_onTextChanged);
    _contactIdController.dispose();
    _relayUrlHintController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
        );
      });
    } else {
      setState(() {
        _hasPermission = false;
        _errorMessage = "Camera access denied. Permit camera use in settings.";
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final parsedId = rawValue.trim();
        final isValid = ContactAddress.isValidFingerprint(parsedId);
        setState(() {
          _contactIdController.text = parsedId;
          _detectedId = parsedId;
          _isValidFormat = isValid;
        });
      }
    }
  }

  Widget _buildViewfinder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: SecureColors.background,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: SecureColors.surfaceDarkSlate, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Stack(
          children: [
            if (_hasPermission == null)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
                ),
              )
            else if (_hasPermission == false)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: SecureColors.panicRed, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        "CAMERA_ACCESS_DENIED",
                        style: TextStyle(
                          color: SecureColors.panicRed,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage ?? "Allow camera access in system settings.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: SecureColors.textSecondary, fontSize: 10.0),
                      ),
                    ],
                  ),
                ),
              )
            else
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<NewChatCubit, NewChatState>(
      listener: (context, state) {
        if (state is NewChatSuccess) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(conversationId: state.conversationId),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: SecureColors.surfaceCharcoal,
              content: Text(
                "SECURE LINK ESTABLISHED // CHANNEL ACTIVE",
                style: TextStyle(color: SecureColors.cryptoGreen, fontFamily: 'Inter'),
              ),
            ),
          );
        } else if (state is NewChatFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1A0505),
              content: Text(
                state.message,
                style: const TextStyle(color: SecureColors.panicRed, fontFamily: 'Inter'),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is NewChatSubmitting;
        final isButtonEnabled = _contactIdController.text.trim().isNotEmpty && !isSubmitting;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "INITIALIZE_NEW_SECURE_LINK",
                      style: TextStyle(
                        color: SecureColors.textPrimary,
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "SECURE_QR_SCANNER",
                      style: TextStyle(
                        color: SecureColors.textSecondary,
                        fontFamily: 'Inter',
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildViewfinder(),
                    if (_detectedId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isValidFormat ? "QR RESOLVED: $_detectedId" : "INVALID FINGERPRINT: $_detectedId",
                        style: TextStyle(
                          color: _isValidFormat ? SecureColors.cryptoGreen : SecureColors.panicRed,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      "MANUAL_FINGERPRINT_HANDSHAKE",
                      style: TextStyle(
                        color: SecureColors.textSecondary,
                        fontFamily: 'Inter',
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _contactIdController,
                      hintText: "Peer Base58/Base64 Fingerprint",
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "RELAY_SERVER_URL_HINT (OPTIONAL)",
                      style: TextStyle(
                        color: SecureColors.textSecondary,
                        fontFamily: 'Inter',
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _relayUrlHintController,
                      hintText: "wss://relay.example.com",
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? SecureColors.cyberBlue : SecureColors.surfaceDarkSlate,
                        foregroundColor: isButtonEnabled ? SecureColors.background : SecureColors.textSecondary,
                        disabledBackgroundColor: SecureColors.surfaceDarkSlate,
                        disabledForegroundColor: SecureColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      onPressed: isButtonEnabled
                          ? () {
                              context.read<NewChatCubit>().initiateNewChat(
                                    fingerprint: _contactIdController.text,
                                    relayUrlHint: _relayUrlHintController.text,
                                  );
                            }
                          : null,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(SecureColors.background),
                              ),
                            )
                          : const Text(
                              "INITIATE_SECURE_LINK",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontSize: 13.0,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
```

#### E. Refactored `lib/features/chat/presentation/widgets/status_app_bar.dart`

```dart
// Update line 54 string from:
// "MATRIX PROTOCOL NODE"
// To:
// "DECENTRALIZED NODE"
```

---

## 5. Verification Method

1. **Static Analysis**:
   ```bash
   flutter analyze lib/features/chat/
   ```
   *Expected result*: 0 issues found.

2. **Clean Architecture Layering Audit**:
   ```bash
   grep -rn "LocalStorageRepository" lib/features/chat/presentation/screens/ lib/features/chat/presentation/widgets/
   grep -rn "RelayTransportAdapter" lib/features/chat/presentation/screens/ lib/features/chat/presentation/widgets/
   ```
   *Expected result*: 0 matches. All data storage and transport references are confined to `lib/features/chat/presentation/bloc/`.

3. **Validation & Matrix Rejection Test**:
   - Supply `@user:matrix.org` as fingerprint in `NewChatCubit`.
   - *Expected result*: `NewChatFailure` state emitted, contact rejected.
   - Supply `8f3a9b1c5e7d2f4a` as fingerprint in `NewChatCubit`.
   - *Expected result*: `NewChatSuccess` state emitted, contact and conversation saved to `LocalStorageRepository`.

4. **Real-time Stream Updates Test**:
   - Inject simulated `MessageEnvelope` into `RelayTransportAdapter.simulateIncomingEnvelope(...)`.
   - *Expected result*: `ChatListBloc` receives stream event, updates `Conversation`, increments `unreadCount`, and emits `ChatListLoaded`.

---
*Report compiled by Explorer 2 for Milestone 4.*
