import 'dart:typed_data';

/// Envelope for anything encrypted with AES-GCM (note bodies, titles, wrapped
/// keys). Kept decoupled from Drift/UI so the same shape can be reused for the
/// future encrypted export/import format.
class EncryptedPayload {
  const EncryptedPayload({
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  /// Random 12-byte AES-GCM nonce. Must never be reused with the same key.
  final Uint8List nonce;

  /// Encrypted bytes.
  final Uint8List ciphertext;

  /// 16-byte GCM authentication tag.
  final Uint8List mac;
}
