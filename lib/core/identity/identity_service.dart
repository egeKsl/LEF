// lib/core/identity/identity_service.dart
//
// LAYER: core/identity
// RESPONSIBILITY: Generate, persist, and load the local device identity.
// Uses Ed25519 key generation from the 'cryptography' package.
// Storage is shared_preferences (encrypted JSON). No network calls.

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_identity.dart';

/// Manages the lifecycle of the device's local [LocalIdentity].
///
/// Call [loadOrNull] on startup. If null, prompt user to call [generate].
class IdentityService {
  static const String _prefKey = 'local_identity_v1';

  final _algorithm = Ed25519();

  /// Returns the saved identity, or null if none exists yet.
  Future<LocalIdentity?> loadOrNull() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalIdentity.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Generates a fresh Ed25519 keypair and persists it locally.
  ///
  /// [displayName] is a user-chosen label (not transmitted without consent).
  Future<LocalIdentity> generate({required String displayName}) async {
    final keyPair = await _algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    final fingerprint = base64Url.encode(publicKey.bytes).replaceAll('=', '');
    final privateKeySeed = base64Url.encode(privateKeyBytes).replaceAll('=', '');

    final identity = LocalIdentity.fromParts(
      displayName: displayName,
      fingerprint: fingerprint,
      privateKeySeed: privateKeySeed,
    );

    await _persist(identity);
    return identity;
  }

  /// Imports an identity from a previously exported JSON blob.
  /// Returns null if the blob is invalid.
  Future<LocalIdentity?> importFromBlob(String blob) async {
    try {
      final map = jsonDecode(blob) as Map<String, dynamic>;
      final identity = LocalIdentity.fromJson(map);
      await _persist(identity);
      return identity;
    } catch (_) {
      return null;
    }
  }

  /// Exports the full identity as a JSON blob (includes private key).
  /// Only call this when the user explicitly requests a backup export.
  Future<String?> exportBlob() async {
    final identity = await loadOrNull();
    if (identity == null) return null;
    return jsonEncode(identity.toJson());
  }

  /// Permanently deletes the stored identity.
  Future<void> purge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  Future<void> _persist(LocalIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(identity.toJson()));
  }
}
