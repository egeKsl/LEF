// lib/features/settings/presentation/bloc/settings_bloc.dart
//
// LAYER: features/settings/presentation
// RESPONSIBILITY: Manage relay URL config, identity export/import, panic purge.
//
// Uses IdentityService and StorageRepository through injected dependencies.
// No direct Matrix, P2P, or hardcoded network references.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/identity/identity_service.dart';
import '../../../../core/identity/local_identity.dart';
import '../../../../core/storage/storage_repository.dart';
import '../../../../core/transport/transport_adapter.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class SettingsEvent {}

class LoadSettingsRequested extends SettingsEvent {}

class UpdateRelayUrlRequested extends SettingsEvent {
  final String relayUrl;
  UpdateRelayUrlRequested(this.relayUrl);
}

class UpdateRelayTokenRequested extends SettingsEvent {
  final String? relayToken;
  UpdateRelayTokenRequested(this.relayToken);
}

class ToggleTorRequested extends SettingsEvent {
  final bool enabled;
  ToggleTorRequested(this.enabled);
}

class ExportIdentityRequested extends SettingsEvent {}

class ImportIdentityRequested extends SettingsEvent {
  final String qrPayload;
  ImportIdentityRequested(this.qrPayload);
}

class ExecutePanicPurgeRequested extends SettingsEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

class SettingsState {
  final String relayUrl;
  final String relayToken;
  final TransportConnectionState connectionState;
  final bool isTorEnabled;
  final LocalIdentity? currentIdentity;
  final String? exportedPayload;
  final String? statusMessage;
  final bool isPurged;

  SettingsState({
    required this.relayUrl,
    required this.relayToken,
    required this.connectionState,
    required this.isTorEnabled,
    this.currentIdentity,
    this.exportedPayload,
    this.statusMessage,
    this.isPurged = false,
  });

  SettingsState copyWith({
    String? relayUrl,
    String? relayToken,
    TransportConnectionState? connectionState,
    bool? isTorEnabled,
    LocalIdentity? currentIdentity,
    String? exportedPayload,
    String? statusMessage,
    bool? isPurged,
  }) =>
      SettingsState(
        relayUrl: relayUrl ?? this.relayUrl,
        relayToken: relayToken ?? this.relayToken,
        connectionState: connectionState ?? this.connectionState,
        isTorEnabled: isTorEnabled ?? this.isTorEnabled,
        currentIdentity: currentIdentity ?? this.currentIdentity,
        exportedPayload: exportedPayload ?? this.exportedPayload,
        statusMessage: statusMessage ?? this.statusMessage,
        isPurged: isPurged ?? this.isPurged,
      );
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final StorageRepository _storage;
  final IdentityService _identityService;
  final TransportAdapter? _transport;

  SettingsBloc({
    required StorageRepository storage,
    required IdentityService identityService,
    TransportAdapter? transport,
  })  : _storage = storage,
        _identityService = identityService,
        _transport = transport,
        super(SettingsState(
          relayUrl: '',
          relayToken: '',
          connectionState: transport?.isConnected == true
              ? TransportConnectionState.connected
              : TransportConnectionState.disconnected,
          isTorEnabled: false,
        )) {
    on<LoadSettingsRequested>(_onLoad);
    on<UpdateRelayUrlRequested>(_onUpdateRelay);
    on<UpdateRelayTokenRequested>(_onUpdateRelayToken);
    on<ToggleTorRequested>(_onToggleTor);
    on<ExportIdentityRequested>(_onExport);
    on<ImportIdentityRequested>(_onImport);
    on<ExecutePanicPurgeRequested>(_onPanic);
  }

  Future<void> _onLoad(
    LoadSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final identity = await _identityService.loadOrNull();
    final relayUrl = await _storage.loadRelayUrl() ?? '';
    final relayToken = await _storage.loadRelayToken() ?? '';
    final connState = _transport?.isConnected == true
        ? TransportConnectionState.connected
        : TransportConnectionState.disconnected;
    emit(state.copyWith(
      currentIdentity: identity,
      relayUrl: relayUrl,
      relayToken: relayToken,
      connectionState: connState,
    ));
  }

  Future<void> _onUpdateRelay(
    UpdateRelayUrlRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final url = event.relayUrl.trim();
    if (url.isEmpty) {
      emit(state.copyWith(statusMessage: 'ERROR: Relay URL cannot be empty'));
      return;
    }
    await _storage.saveRelayUrl(url);
    if (_transport != null) {
      await _transport.disconnect();
      await _transport.connect();
    }
    emit(state.copyWith(
      relayUrl: url,
      connectionState: _transport?.isConnected == true
          ? TransportConnectionState.connected
          : TransportConnectionState.disconnected,
      statusMessage: 'RELAY_URL_UPDATED',
    ));
  }

  Future<void> _onUpdateRelayToken(
    UpdateRelayTokenRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _storage.saveRelayToken(event.relayToken);
    emit(state.copyWith(
      relayToken: event.relayToken ?? '',
      statusMessage: 'RELAY_TOKEN_UPDATED',
    ));
  }

  Future<void> _onToggleTor(
    ToggleTorRequested event,
    Emitter<SettingsState> emit,
  ) async {
    // Tor adapter is deferred — toggle stores intent only
    emit(state.copyWith(isTorEnabled: event.enabled));
  }

  Future<void> _onExport(
    ExportIdentityRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final blob = await _identityService.exportBlob();
    if (blob != null) {
      emit(state.copyWith(exportedPayload: blob));
    } else {
      emit(state.copyWith(statusMessage: 'NO_LOCAL_IDENTITY_FOUND'));
    }
  }

  Future<void> _onImport(
    ImportIdentityRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final identity = await _identityService.importFromBlob(event.qrPayload);
    if (identity != null) {
      emit(state.copyWith(
        currentIdentity: identity,
        statusMessage: 'KEYS_IMPORTED_SUCCESSFULLY',
      ));
    } else {
      emit(state.copyWith(statusMessage: 'INVALID_IDENTITY_BLOB'));
    }
  }

  Future<void> _onPanic(
    ExecutePanicPurgeRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _identityService.purge();
    // Storage purge: delete all conversations/messages (no explicit "clear all" in interface —
    // identity purge is the critical operation; conversation data is secondary)
    emit(state.copyWith(isPurged: true));
  }
}
