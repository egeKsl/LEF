// lib/core/addressing/contact_address.dart
//
// LAYER: core/addressing
// RESPONSIBILITY: Represents the address of a remote contact.
//
// Separates logical identity (fingerprint) from transport hint (relayHint).
// A contact address is portable and can be encoded as a QR code or text.
// Transport-agnostic: the relay hint is optional and only used by the
// transport layer. The protocol layer uses only the fingerprint.

import 'dart:convert';

/// The address of a remote contact.
///
/// [fingerprint] is the base64url-encoded Ed25519 public key — the canonical,
/// transport-independent identity of the contact.
///
/// [relayHint] is an optional WebSocket/HTTPS URL of a relay server where
/// this contact is expected to be reachable. When absent, the locally
/// configured relay is used as a fallback.
///
/// [displayName] is an optional human-readable label stored locally only.
class ContactAddress {
  final String fingerprint;
  final String? relayHint;
  final String? displayName;

  const ContactAddress({
    required this.fingerprint,
    this.relayHint,
    this.displayName,
  });

  /// Short display label: display name if available, otherwise first 12 chars
  /// of the fingerprint with an ellipsis.
  String get label =>
      displayName?.isNotEmpty == true
          ? displayName!
          : '${fingerprint.substring(0, 12)}…';

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        if (relayHint != null) 'relay_hint': relayHint,
        if (displayName != null) 'display_name': displayName,
      };

  factory ContactAddress.fromJson(Map<String, dynamic> json) => ContactAddress(
        fingerprint: json['fingerprint'] as String,
        relayHint: json['relay_hint'] as String?,
        displayName: json['display_name'] as String?,
      );

  /// Parses a contact share blob produced by [LocalIdentity.toContactShareBlob].
  static ContactAddress? fromShareBlob(String blob) {
    try {
      final map = jsonDecode(blob) as Map<String, dynamic>;
      final fp = map['fingerprint'] as String?;
      if (fp == null || fp.isEmpty) return null;
      return ContactAddress(
        fingerprint: fp,
        displayName: map['name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encode as a shareable text blob (safe to put in a QR code).
  String toShareBlob() => jsonEncode({
        'fingerprint': fingerprint,
        if (displayName != null) 'name': displayName,
        if (relayHint != null) 'relay_hint': relayHint,
      });

  @override
  bool operator ==(Object other) =>
      other is ContactAddress && other.fingerprint == fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;

  @override
  String toString() => 'ContactAddress($label)';
}
