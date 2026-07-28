// lib/core/messaging/conversation.dart
//
// LAYER: core/messaging
// RESPONSIBILITY: Represents a conversation thread with one contact.

import '../addressing/contact_address.dart';
import 'message_envelope.dart';

/// A conversation thread between the local identity and one remote contact.
class Conversation {
  /// Unique stable ID (derived from the remote fingerprint).
  final String id;

  /// The remote party's address.
  final ContactAddress contact;

  /// The most recent message, used for list previews.
  final MessageEnvelope? lastMessage;

  /// Number of messages not yet read by the user.
  final int unreadCount;

  /// Ordered list of messages (newest first).
  final List<MessageEnvelope> messages;

  const Conversation({
    required this.id,
    required this.contact,
    this.lastMessage,
    this.unreadCount = 0,
    this.messages = const [],
  });

  /// Stable ID based on the contact's fingerprint.
  static String idFor(String contactFingerprint) => contactFingerprint;

  Conversation copyWith({
    ContactAddress? contact,
    MessageEnvelope? lastMessage,
    int? unreadCount,
    List<MessageEnvelope>? messages,
  }) =>
      Conversation(
        id: id,
        contact: contact ?? this.contact,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        messages: messages ?? this.messages,
      );
}
