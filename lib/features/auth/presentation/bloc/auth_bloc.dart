// lib/features/auth/presentation/bloc/auth_bloc.dart
//
// LAYER: features/auth/presentation
// RESPONSIBILITY: BLoC managing local identity creation and loading.
//
// No Matrix. No network. Identity is generated locally using Ed25519 keypairs.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/identity/identity_service.dart';
import '../../../../core/identity/local_identity.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuthEvent {}

/// Check whether a local identity already exists on this device.
class CheckLocalIdentityRequested extends AuthEvent {}

/// Generate a fresh Ed25519 keypair with the given display name.
class GenerateIdentityRequested extends AuthEvent {
  final String displayName;
  GenerateIdentityRequested({required this.displayName});
}

/// Import an identity from a previously exported JSON blob.
class ImportIdentityRequested extends AuthEvent {
  final String blob;
  ImportIdentityRequested({required this.blob});
}

/// Permanently delete the local identity.
class PurgeIdentityRequested extends AuthEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthReady extends AuthState {
  final LocalIdentity identity;
  AuthReady(this.identity);
}

/// No identity exists yet — user must generate or import one.
class AuthNoIdentity extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IdentityService _identityService;

  AuthBloc(this._identityService) : super(AuthInitial()) {
    on<CheckLocalIdentityRequested>(_onCheck);
    on<GenerateIdentityRequested>(_onGenerate);
    on<ImportIdentityRequested>(_onImport);
    on<PurgeIdentityRequested>(_onPurge);
  }

  Future<void> _onCheck(
    CheckLocalIdentityRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final identity = await _identityService.loadOrNull();
    if (identity != null) {
      emit(AuthReady(identity));
    } else {
      emit(AuthNoIdentity());
    }
  }

  Future<void> _onGenerate(
    GenerateIdentityRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final identity = await _identityService.generate(
        displayName: event.displayName.trim(),
      );
      emit(AuthReady(identity));
    } catch (e) {
      emit(AuthFailure('Identity generation failed: $e'));
    }
  }

  Future<void> _onImport(
    ImportIdentityRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final identity = await _identityService.importFromBlob(event.blob);
    if (identity != null) {
      emit(AuthReady(identity));
    } else {
      emit(AuthFailure('Invalid identity blob — could not import.'));
    }
  }

  Future<void> _onPurge(
    PurgeIdentityRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _identityService.purge();
    emit(AuthNoIdentity());
  }
}