// lib/core/storage/storage_repository.dart
//
// LAYER: core/storage
// RESPONSIBILITY: Abstract contract for all local persistence operations.
//
// UI layers and the messaging service only talk to this interface.
// The concrete implementation (SQLite via sqflite) is in app_database.dart.

import '../messaging/message_envelope.dart';
import '../messaging/conversation.dart';
import '../addressing/contact_address.dart';

export '../messaging/conversation.dart';

/// Abstract local storage contract.
abstract class StorageRepository {
  // ── Conversations ────────────────────────────────────────────────────────

  /// Return all conversations sorted by last message timestamp (newest first).
  Future<List<Conversation>> loadConversations();

  /// Upsert a conversation record. Creates it if not present.
  Future<void> saveConversation(Conversation conversation);

  /// Delete a conversation and all its messages.
  Future<void> deleteConversation(String conversationId);

  // ── Messages ─────────────────────────────────────────────────────────────

  /// Return all messages for [conversationId], newest first.
  Future<List<MessageEnvelope>> loadMessages(String conversationId);

  /// Persist a new message. Also updates the parent conversation's last-message.
  Future<void> saveMessage(MessageEnvelope envelope);

  /// Update only the delivery status of an existing message.
  Future<void> updateMessageStatus(String messageId, DeliveryStatus status);

  // ── Contacts ─────────────────────────────────────────────────────────────

  /// Return all saved contacts.
  Future<List<ContactAddress>> loadContacts();

  /// Upsert a contact.
  Future<void> saveContact(ContactAddress contact);

  /// Delete a contact by fingerprint.
  Future<void> deleteContact(String fingerprint);

  // ── Relay settings ───────────────────────────────────────────────────────

  /// Return the currently configured relay URL, or null if not set.
  Future<String?> loadRelayUrl();

  /// Persist the relay URL.
  Future<void> saveRelayUrl(String url);

  /// Return the relay bootstrap token, if configured.
  Future<String?> loadRelayToken();

  /// Persist the relay bootstrap token.
  Future<void> saveRelayToken(String? token);
}
