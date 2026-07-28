// lib/core/messaging/messaging_service.dart
//
// LAYER: core/messaging
// RESPONSIBILITY: Orchestrates message send/receive between identity,
// encryption, transport, and storage layers.
//
// This is the single entry point for all messaging operations.
// UI-facing BLoCs/Cubits call this service; they never touch transport directly.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../identity/local_identity.dart';
import '../addressing/contact_address.dart';
import '../transport/transport_adapter.dart';
import '../storage/storage_repository.dart';
import 'message_envelope.dart';
import 'encryption_interface.dart';

// ── Extensions (public key bytes helpers) ────────────────────────────────────

extension ContactAddressPublicKey on ContactAddress {
  Uint8List get publicKeyBytes =>
      base64Url.decode(base64Url.normalize(fingerprint));
}

extension MessageEnvelopePublicKey on MessageEnvelope {
  Uint8List get senderPublicKeyBytes =>
      base64Url.decode(base64Url.normalize(senderFingerprint));
}

// ── Service ──────────────────────────────────────────────────────────────────

/// Orchestrates the full message lifecycle.
///
/// Dependency graph:
///   MessagingService
///     → TransportAdapter  (send/receive bytes)
///     → EncryptionInterface (encrypt/decrypt payloads)
///     → StorageRepository (persist conversations + messages)
class MessagingService {
  final TransportAdapter _transport;
  final EncryptionInterface _encryption;
  final StorageRepository _storage;
  final LocalIdentity _identity;

  final _uuid = const Uuid();
  StreamSubscription<MessageEnvelope>? _incomingSub;

  MessagingService({
    required TransportAdapter transport,
    required EncryptionInterface encryption,
    required StorageRepository storage,
    required LocalIdentity identity,
  })  : _transport = transport,
        _encryption = encryption,
        _storage = storage,
        _identity = identity;

  /// Connect transport and start listening for incoming envelopes.
  Future<void> start() async {
    await _transport.connect();
    _incomingSub = _transport.incomingEnvelopes.listen(_handleIncoming);
  }

  /// Gracefully disconnect and stop listening.
  Future<void> stop() async {
    await _incomingSub?.cancel();
    await _transport.disconnect();
  }

  /// Sends a plaintext [body] to [recipient].
  ///
  /// Encrypts, builds an envelope, persists it, and hands it to transport.
  Future<MessageEnvelope> send({
    required ContactAddress recipient,
    required String body,
  }) async {
    final ciphertext = await _encryption.encrypt(
      plaintext: body,
      recipientPublicKeyBytes: recipient.publicKeyBytes,
      senderPrivateKeyBytes: _identity.privateKeySeedBytes,
    );

    final envelope = MessageEnvelope(
      id: _uuid.v4(),
      senderFingerprint: _identity.fingerprint,
      recipientFingerprint: recipient.fingerprint,
      encryptedPayload: ciphertext,
      plaintextBody: body,
      timestamp: DateTime.now().toUtc(),
      status: DeliveryStatus.pending,
      isOutgoing: true,
    );

    await _storage.saveMessage(envelope);

    final ok = await _transport.sendEnvelope(envelope);
    final updated = envelope.copyWith(
      status: ok ? DeliveryStatus.sent : DeliveryStatus.failed,
    );
    await _storage.updateMessageStatus(updated.id, updated.status);

    return updated;
  }

  /// Handles an incoming envelope from the transport layer.
  Future<void> _handleIncoming(MessageEnvelope raw) async {
    final plaintext = await _encryption.decrypt(
      ciphertext: raw.encryptedPayload,
      senderPublicKeyBytes: raw.senderPublicKeyBytes,
      recipientPrivateKeyBytes: _identity.privateKeySeedBytes,
    );

    final decrypted = raw.copyWith(
      plaintextBody: plaintext ?? '[decryption failed]',
      status: DeliveryStatus.delivered,
    );

    await _storage.saveMessage(decrypted);
  }

  /// Load all conversations from storage.
  Future<List<Conversation>> loadConversations() =>
      _storage.loadConversations();

  /// Load all messages for a given [conversationId].
  Future<List<MessageEnvelope>> loadMessages(String conversationId) =>
      _storage.loadMessages(conversationId);
}
