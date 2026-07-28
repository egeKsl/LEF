// lib/core/messaging/message_envelope.dart
//
// LAYER: core/messaging
// RESPONSIBILITY: The sealed message unit that travels through the transport layer.
//
// An envelope carries an encrypted payload plus metadata needed for
// routing and delivery tracking. The transport layer is NOT allowed to
// inspect or modify the payload — it is opaque bytes.

/// Delivery states for a [MessageEnvelope].
enum DeliveryStatus {
  /// Not yet attempted.
  pending,
  /// Handed to the transport layer successfully.
  sent,
  /// Acknowledged by the recipient's relay or device.
  delivered,
  /// All send attempts failed.
  failed,
}

/// A single message envelope in the SimpleX-inspired protocol.
///
/// The [encryptedPayload] is the ciphertext produced by the encryption layer.
/// The transport layer treats it as opaque bytes; it never decrypts it.
///
/// [senderFingerprint] and [recipientFingerprint] are base64url-encoded
/// Ed25519 public keys used for routing — NOT human-readable IDs.
class MessageEnvelope {
  /// Unique message ID (UUID v4).
  final String id;

  /// Sender's public key fingerprint (base64url).
  final String senderFingerprint;

  /// Recipient's public key fingerprint (base64url).
  final String recipientFingerprint;

  /// Ciphertext produced by the encryption layer (base64-encoded bytes).
  final String encryptedPayload;

  /// Plaintext body — only populated locally after decryption. Never sent.
  final String? plaintextBody;

  /// UTC creation timestamp.
  final DateTime timestamp;

  /// Current delivery state.
  final DeliveryStatus status;

  /// True if this message was sent by the local device.
  final bool isOutgoing;

  const MessageEnvelope({
    required this.id,
    required this.senderFingerprint,
    required this.recipientFingerprint,
    required this.encryptedPayload,
    this.plaintextBody,
    required this.timestamp,
    this.status = DeliveryStatus.pending,
    required this.isOutgoing,
  });

  MessageEnvelope copyWith({
    DeliveryStatus? status,
    String? plaintextBody,
  }) =>
      MessageEnvelope(
        id: id,
        senderFingerprint: senderFingerprint,
        recipientFingerprint: recipientFingerprint,
        encryptedPayload: encryptedPayload,
        plaintextBody: plaintextBody ?? this.plaintextBody,
        timestamp: timestamp,
        status: status ?? this.status,
        isOutgoing: isOutgoing,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_fp': senderFingerprint,
        'recipient_fp': recipientFingerprint,
        'encrypted_payload': encryptedPayload,
        'plaintext_body': plaintextBody,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'is_outgoing': isOutgoing,
      };

  factory MessageEnvelope.fromJson(Map<String, dynamic> json) =>
      MessageEnvelope(
        id: json['id'] as String,
        senderFingerprint: json['sender_fp'] as String,
        recipientFingerprint: json['recipient_fp'] as String,
        encryptedPayload: json['encrypted_payload'] as String,
        plaintextBody: json['plaintext_body'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: DeliveryStatus.values.byName(json['status'] as String),
        isOutgoing: json['is_outgoing'] as bool,
      );
}
