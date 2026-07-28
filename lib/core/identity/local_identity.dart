// lib/core/identity/local_identity.dart
//
// LAYER: core/identity
// RESPONSIBILITY: Immutable value object representing this device's cryptographic identity.
// No network dependency. No server registration required.

import 'dart:convert';
import 'dart:typed_data';

/// The cryptographic identity of the local device.
///
/// Consists of an Ed25519 keypair. The [fingerprint] is the canonical
/// public representation used as a contact address identifier.
class LocalIdentity {
  /// Human-readable display name chosen by the user.
  final String displayName;

  /// Base64url-encoded Ed25519 public key (32 bytes → ~44 chars).
  final String fingerprint;

  /// Base64url-encoded Ed25519 private key seed (32 bytes).
  ///
  /// NEVER expose this outside the identity layer.
  final String _privateKeySeed;

  const LocalIdentity._({
    required this.displayName,
    required this.fingerprint,
    required String privateKeySeed,
  }) : _privateKeySeed = privateKeySeed;

  /// Creates an identity from already-encoded components.
  factory LocalIdentity.fromParts({
    required String displayName,
    required String fingerprint,
    required String privateKeySeed,
  }) {
    return LocalIdentity._(
      displayName: displayName,
      fingerprint: fingerprint,
      privateKeySeed: privateKeySeed,
    );
  }

  /// The raw private key seed bytes. Only used internally for signing.
  Uint8List get privateKeySeedBytes =>
      base64Url.decode(base64Url.normalize(_privateKeySeed));

  /// The raw public key bytes. Used for verification and address derivation.
  Uint8List get publicKeyBytes =>
      base64Url.decode(base64Url.normalize(fingerprint));

  /// Serialise to a storable/exportable JSON map.
  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'fingerprint': fingerprint,
        'private_key_seed': _privateKeySeed,
      };

  /// Restore from a stored JSON map.
  factory LocalIdentity.fromJson(Map<String, dynamic> json) =>
      LocalIdentity._(
        displayName: json['display_name'] as String,
        fingerprint: json['fingerprint'] as String,
        privateKeySeed: json['private_key_seed'] as String,
      );

  /// Human-readable export blob (for QR or share-as-text).
  /// Contains ONLY the public fingerprint — never the private key.
  String toContactShareBlob() =>
      jsonEncode({'fingerprint': fingerprint, 'name': displayName});

  @override
  String toString() => 'LocalIdentity($displayName · $fingerprint)';
}
