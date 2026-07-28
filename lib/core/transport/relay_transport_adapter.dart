// lib/core/transport/relay_transport_adapter.dart
//
// LAYER: core/transport
// RESPONSIBILITY: WebSocket relay implementation of [TransportAdapter].
//
// Connects to a configurable relay server via WebSocket.
// The relay URL is stored in settings — never hardcoded here.
//
// Wire protocol (JSON over WebSocket):
//   SEND: { "type": "envelope", "id": "...", "sender": "...", "recipient": "...", "payload": "..." }
//   ACK:  { "type": "ack", "id": "..." }
//   RECV: { "type": "envelope", ... }
//
// Tor-readiness: swap [WebSocketChannel.connect] with a SOCKS5-proxied
// connection to add Tor support without changing any other layer.

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../messaging/message_envelope.dart';
import 'transport_adapter.dart';

/// WebSocket relay implementation.
///
/// [relayUrl] must be a valid ws:// or wss:// URI configured in settings.
/// [localFingerprint] identifies this device to the relay for message routing.
class RelayTransportAdapter implements TransportAdapter {
  final String relayUrl;
  final String localFingerprint;
  final String? bootstrapToken;

  WebSocketChannel? _channel;
  final StreamController<MessageEnvelope> _incomingController =
      StreamController<MessageEnvelope>.broadcast();

  bool _connected = false;
  bool _registered = false;
  Timer? _heartbeatTimer;
  StreamSubscription<dynamic>? _wsSub;

  RelayTransportAdapter({
    required this.relayUrl,
    required this.localFingerprint,
    this.bootstrapToken,
  });

  @override
  bool get isConnected => _connected;

  @override
  Stream<MessageEnvelope> get incomingEnvelopes => _incomingController.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    try {
      final uri = Uri.parse(relayUrl);
      _channel = WebSocketChannel.connect(uri);

      _connected = true;
      _registered = false;

      // Register this device with the relay using the minimum bootstrap token.
      _channel!.sink.add(jsonEncode({
        'type': 'register',
        'protocol_version': 1,
        'fingerprint': localFingerprint,
        'token': bootstrapToken ?? '',
      }));

      _wsSub = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) {
          _connected = false;
          _registered = false;
          _heartbeatTimer?.cancel();
        },
        onDone: () {
          _connected = false;
          _registered = false;
          _heartbeatTimer?.cancel();
        },
      );
    } catch (_) {
      _connected = false;
    }
  }

  @override
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _connected = false;
    _registered = false;
  }

  @override
  Future<bool> sendEnvelope(MessageEnvelope envelope) async {
    if (!_connected || _channel == null) return false;
    try {
      final payload = jsonEncode({
        'type': 'envelope',
        'protocol_version': 1,
        'id': envelope.id,
        'sender': envelope.senderFingerprint,
        'recipient': envelope.recipientFingerprint,
        'payload': envelope.encryptedPayload,
        'timestamp': envelope.timestamp.toIso8601String(),
      });
      _channel!.sink.add(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onRawMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String?;
      if (type == 'register_ack') {
        final ok = map['ok'] == true;
        _registered = ok;
        if (ok) {
          final heartbeatSec = (map['heartbeat_sec'] as num?)?.toInt() ?? 30;
          _heartbeatTimer?.cancel();
          _heartbeatTimer = Timer.periodic(Duration(seconds: heartbeatSec), (_) {
            if (_channel == null || !_connected) return;
            _channel!.sink.add(jsonEncode({
              'type': 'heartbeat',
              'protocol_version': 1,
              'now': DateTime.now().toUtc().toIso8601String(),
            }));
          });
        }
        return;
      }
      if (type == 'ack' || type == 'undelivered' || type == 'heartbeat') {
        return;
      }
      if (type != 'envelope') return;

      final envelope = MessageEnvelope(
        id: map['id'] as String,
        senderFingerprint: map['sender'] as String,
        recipientFingerprint: map['recipient'] as String,
        encryptedPayload: map['payload'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        status: DeliveryStatus.delivered,
        isOutgoing: false,
      );
      _incomingController.add(envelope);
    } catch (_) {
      // Malformed message — silently discard
    }
  }
}
