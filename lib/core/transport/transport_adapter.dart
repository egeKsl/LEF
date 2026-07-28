// lib/core/transport/transport_adapter.dart
//
// LAYER: core/transport
// RESPONSIBILITY: Abstract contract for all transport implementations.
//
// The messaging layer only ever talks to this interface.
// Concrete implementations (relay, Tor, direct) are plug-in replaceable
// without touching any other layer.

import '../messaging/message_envelope.dart';

/// Transport connection states for UI observability.
enum TransportConnectionState {
  connected,
  connecting,
  disconnecting,
  disconnected,
  error,
}

/// Abstract transport adapter.
///
/// Implementations:
///   - [RelayTransportAdapter]: WebSocket relay (Phase 1, this release)
///   - TorTransportAdapter: SOCKS5 via Tor daemon (deferred)
///   - DirectTransportAdapter: future device-to-device (deferred)
///
/// Contract:
///   - [connect] MUST be called before [sendEnvelope].
///   - [incomingEnvelopes] is a broadcast stream; subscribe before [connect].
///   - [disconnect] is idempotent.
abstract class TransportAdapter {
  /// Establish the transport connection.
  Future<void> connect();

  /// Tear down the transport connection.
  Future<void> disconnect();

  /// Send an envelope to the relay/peer.
  ///
  /// Returns true if the transport layer accepted the message.
  /// Does NOT guarantee delivery to the final recipient.
  Future<bool> sendEnvelope(MessageEnvelope envelope);

  /// Incoming envelopes from the network (broadcast stream).
  Stream<MessageEnvelope> get incomingEnvelopes;

  /// True while the transport has an active connection.
  bool get isConnected;
}
