// lib/main.dart
//
// Entry point — wires all layers together and injects dependencies.
//
// Dependency order:
//   1. StorageRepository (SQLite)
//   2. IdentityService (Ed25519 keypair)
//   3. TransportAdapter (relay, URL from storage)
//   4. EncryptionInterface (stub → real in crypto phase)
//   5. MessagingService (orchestrates 2–4)
//   6. Feature BLoCs/Cubits receive MessagingService

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/secure_colors.dart';
import 'config/routes/app_routes.dart';
import 'core/identity/identity_service.dart';
import 'core/messaging/encryption_interface.dart';
import 'core/messaging/messaging_service.dart';
import 'core/storage/app_database.dart';
import 'core/transport/relay_transport_adapter.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/bloc/chat_list_cubit.dart';
import 'features/chat_room/presentation/bloc/chat_room_cubit.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Layer 1: Storage ─────────────────────────────────────────────────────
  final storage = AppDatabase();

  // ── Layer 2: Identity ────────────────────────────────────────────────────
  final identityService = IdentityService();
  final identity = await identityService.loadOrNull();
  final hasIdentity = identity != null;

  // ── Layer 3: Transport ───────────────────────────────────────────────────
  final relayUrl = await storage.loadRelayUrl() ?? '';
  final relayToken = await storage.loadRelayToken() ?? '';
  final transport = relayUrl.isNotEmpty && identity != null
      ? RelayTransportAdapter(
          relayUrl: relayUrl,
          localFingerprint: identity.fingerprint,
          bootstrapToken: relayToken,
        )
      : null;

  // ── Layer 4: Encryption ──────────────────────────────────────────────────
  final encryption = StubEncryption();

  // ── Layer 5: Messaging ───────────────────────────────────────────────────
  MessagingService? messaging;
  if (identity != null && transport != null) {
    messaging = MessagingService(
      transport: transport,
      encryption: encryption,
      storage: storage,
      identity: identity,
    );
    await messaging.start();
  }

  final initialRoute = hasIdentity
      ? (messaging != null ? AppRoutes.chatList : AppRoutes.settings)
      : AppRoutes.auth;

  runApp(
    _App(
      initialRoute: initialRoute,
      identityService: identityService,
      messaging: messaging,
      storage: storage,
      transport: transport,
    ),
  );
}

class _App extends StatelessWidget {
  final String initialRoute;
  final IdentityService identityService;
  final MessagingService? messaging;
  final AppDatabase storage;
  final RelayTransportAdapter? transport;

  const _App({
    required this.initialRoute,
    required this.identityService,
    required this.messaging,
    required this.storage,
    required this.transport,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(identityService)
            ..add(CheckLocalIdentityRequested()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(
            storage: storage,
            identityService: identityService,
            transport: transport,
          ),
        ),
        if (messaging != null) ...[
          BlocProvider<ChatListCubit>(
            create: (_) => ChatListCubit(messaging!),
          ),
          BlocProvider<ChatRoomCubit>(
            create: (_) => ChatRoomCubit(messaging!),
          ),
        ],
      ],
      child: MaterialApp(
        title: 'SecureLink',
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
          tabBarTheme: const TabBarThemeData(
            indicatorColor: SecureColors.cyberBlue,
            labelColor: SecureColors.textPrimary,
            unselectedLabelColor: SecureColors.textSecondary,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
                color: SecureColors.textPrimary, fontFamily: 'Inter'),
            bodyMedium: TextStyle(
                color: SecureColors.textSecondary, fontFamily: 'Inter'),
          ),
        ),
        initialRoute: initialRoute,
        routes: AppRoutes.routesFor(storage),
      ),
    );
  }
}
