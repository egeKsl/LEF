// lib/core/storage/app_database.dart
//
// LAYER: core/storage
// RESPONSIBILITY: SQLite-backed implementation of [StorageRepository].
//
// Uses sqflite. All data is stored locally on-device.
// No data ever leaves this layer except through the messaging service.

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../addressing/contact_address.dart';
import '../messaging/message_envelope.dart';
import 'storage_repository.dart';

/// SQLite implementation of [StorageRepository].
class AppDatabase implements StorageRepository {
  static const _dbName = 'securelink_v1.db';
  static const _dbVersion = 1;
  static const _prefRelayKey = 'relay_url_v1';
  static const _prefRelayTokenKey = 'relay_token_v1';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        fingerprint TEXT PRIMARY KEY,
        display_name TEXT,
        relay_hint TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        contact_fingerprint TEXT NOT NULL,
        last_message_json TEXT,
        unread_count INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_fp TEXT NOT NULL,
        recipient_fp TEXT NOT NULL,
        encrypted_payload TEXT NOT NULL,
        plaintext_body TEXT,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        is_outgoing INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_conv ON messages(conversation_id, timestamp DESC)',
    );
  }

  // ── Conversations ────────────────────────────────────────────────────────

  @override
  Future<List<Conversation>> loadConversations() async {
    final db = await _database;
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return Future.wait(rows.map(_rowToConversation));
  }

  Future<Conversation> _rowToConversation(Map<String, dynamic> row) async {
    final contact = await _loadContact(row['contact_fingerprint'] as String);
    final lastMsgJson = row['last_message_json'] as String?;
    final lastMsg = lastMsgJson != null
        ? MessageEnvelope.fromJson(
            jsonDecode(lastMsgJson) as Map<String, dynamic>)
        : null;
    return Conversation(
      id: row['id'] as String,
      contact: contact ??
          ContactAddress(fingerprint: row['contact_fingerprint'] as String),
      lastMessage: lastMsg,
      unreadCount: row['unread_count'] as int,
    );
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final db = await _database;
    await db.insert(
      'conversations',
      {
        'id': conversation.id,
        'contact_fingerprint': conversation.contact.fingerprint,
        'last_message_json': conversation.lastMessage != null
            ? jsonEncode(conversation.lastMessage!.toJson())
            : null,
        'unread_count': conversation.unreadCount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await saveContact(conversation.contact);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final db = await _database;
    await db.delete('messages',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
    await db.delete('conversations',
        where: 'id = ?', whereArgs: [conversationId]);
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<List<MessageEnvelope>> loadMessages(String conversationId) async {
    final db = await _database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(_rowToEnvelope).toList();
  }

  MessageEnvelope _rowToEnvelope(Map<String, dynamic> row) =>
      MessageEnvelope(
        id: row['id'] as String,
        senderFingerprint: row['sender_fp'] as String,
        recipientFingerprint: row['recipient_fp'] as String,
        encryptedPayload: row['encrypted_payload'] as String,
        plaintextBody: row['plaintext_body'] as String?,
        timestamp: DateTime.parse(row['timestamp'] as String),
        status: DeliveryStatus.values.byName(row['status'] as String),
        isOutgoing: (row['is_outgoing'] as int) == 1,
      );

  @override
  Future<void> saveMessage(MessageEnvelope envelope) async {
    final db = await _database;
    final convId = Conversation.idFor(
      envelope.isOutgoing
          ? envelope.recipientFingerprint
          : envelope.senderFingerprint,
    );

    await db.insert(
      'messages',
      {
        'id': envelope.id,
        'conversation_id': convId,
        'sender_fp': envelope.senderFingerprint,
        'recipient_fp': envelope.recipientFingerprint,
        'encrypted_payload': envelope.encryptedPayload,
        'plaintext_body': envelope.plaintextBody,
        'timestamp': envelope.timestamp.toIso8601String(),
        'status': envelope.status.name,
        'is_outgoing': envelope.isOutgoing ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update conversation's last-message + unread count
    await db.rawInsert('''
      INSERT INTO conversations(id, contact_fingerprint, last_message_json, unread_count, updated_at)
      VALUES(?, ?, ?, COALESCE((SELECT unread_count FROM conversations WHERE id = ?), 0) + ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        last_message_json = excluded.last_message_json,
        unread_count = conversations.unread_count + ?,
        updated_at = excluded.updated_at
    ''', [
      convId,
      envelope.isOutgoing
          ? envelope.recipientFingerprint
          : envelope.senderFingerprint,
      jsonEncode(envelope.toJson()),
      convId,
      envelope.isOutgoing ? 0 : 1,
      DateTime.now().toUtc().toIso8601String(),
      envelope.isOutgoing ? 0 : 1,
    ]);
  }

  @override
  Future<void> updateMessageStatus(
      String messageId, DeliveryStatus status) async {
    final db = await _database;
    await db.update(
      'messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // ── Contacts ─────────────────────────────────────────────────────────────

  Future<ContactAddress?> _loadContact(String fingerprint) async {
    final db = await _database;
    final rows = await db.query(
      'contacts',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ContactAddress(
      fingerprint: rows.first['fingerprint'] as String,
      displayName: rows.first['display_name'] as String?,
      relayHint: rows.first['relay_hint'] as String?,
    );
  }

  @override
  Future<List<ContactAddress>> loadContacts() async {
    final db = await _database;
    final rows = await db.query('contacts');
    return rows
        .map((r) => ContactAddress(
              fingerprint: r['fingerprint'] as String,
              displayName: r['display_name'] as String?,
              relayHint: r['relay_hint'] as String?,
            ))
        .toList();
  }

  @override
  Future<void> saveContact(ContactAddress contact) async {
    final db = await _database;
    await db.insert(
      'contacts',
      {
        'fingerprint': contact.fingerprint,
        'display_name': contact.displayName,
        'relay_hint': contact.relayHint,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteContact(String fingerprint) async {
    final db = await _database;
    await db.delete('contacts',
        where: 'fingerprint = ?', whereArgs: [fingerprint]);
  }

  // ── Relay settings ───────────────────────────────────────────────────────

  @override
  Future<String?> loadRelayUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefRelayKey);
  }

  @override
  Future<void> saveRelayUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRelayKey, url);
  }

  @override
  Future<String?> loadRelayToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefRelayTokenKey);
  }

  @override
  Future<void> saveRelayToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_prefRelayTokenKey);
      return;
    }
    await prefs.setString(_prefRelayTokenKey, token);
  }
}
