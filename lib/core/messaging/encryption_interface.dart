// lib/core/messaging/encryption_interface.dart
//
// LAYER: core/messaging
// RESPONSIBILITY: Abstract E2E encryption contract + stub implementation.
//
// The stub XOR-encodes the plaintext with a fixed byte so the architecture
// compiles and the flow works end-to-end. Replace StubEncryption with a
// proper NaCl/X25519+ChaCha20-Poly1305 implementation in the crypto phase.

import 'dart:convert';
import 'dart:typed_data';

/// Contract for the encryption layer.
///
/// Implementations must be stateless with respect to the message content.
/// Key material is passed per-call so the interface remains transport-agnostic.
abstract class EncryptionInterface {
  /// Encrypt [plaintext] for [recipientPublicKeyBytes].
  ///
  /// Returns base64-encoded ciphertext ready for inclusion in a [MessageEnvelope].
  Future<String> encrypt({
    required String plaintext,
    required Uint8List recipientPublicKeyBytes,
    required Uint8List senderPrivateKeyBytes,
  });

  /// Decrypt [ciphertext] using the local private key.
  ///
  /// Returns the plaintext string, or null if decryption fails.
  Future<String?> decrypt({
    required String ciphertext,
    required Uint8List senderPublicKeyBytes,
    required Uint8List recipientPrivateKeyBytes,
  });
}

/// STUB: XOR-based placeholder. NOT cryptographically secure.
///
/// Replace with NaCl box (X25519 + XSalsa20-Poly1305) or
/// ChaCha20-Poly1305 + HKDF in the encryption phase.
class StubEncryption implements EncryptionInterface {
  static const int _xorKey = 0x5A;

  @override
  Future<String> encrypt({
    required String plaintext,
    required Uint8List recipientPublicKeyBytes,
    required Uint8List senderPrivateKeyBytes,
  }) async {
    final bytes = utf8.encode(plaintext);
    final xored = Uint8List.fromList(bytes.map((b) => b ^ _xorKey).toList());
    return base64.encode(xored);
  }

  @override
  Future<String?> decrypt({
    required String ciphertext,
    required Uint8List senderPublicKeyBytes,
    required Uint8List recipientPrivateKeyBytes,
  }) async {
    try {
      final bytes = base64.decode(ciphertext);
      final xored = Uint8List.fromList(bytes.map((b) => b ^ _xorKey).toList());
      return utf8.decode(xored);
    } catch (_) {
      return null;
    }
  }
}
