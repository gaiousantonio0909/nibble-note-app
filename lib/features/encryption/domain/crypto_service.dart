import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encrypted_payload.dart';

/// KDF parameters that describe how a KEK was derived from a user PIN.
///
/// These are stored in the vault row alongside the wrapped DEK so the app can
/// re-derive the same key on future unlocks — and so parameters can be
/// upgraded over time without breaking existing vaults.
class KdfParams {
  const KdfParams({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
  });

  /// OWASP 2023 baseline for Argon2id on mobile: 19 MiB, 2 iterations, p=1.
  static const KdfParams defaults = KdfParams(
    memoryKib: 19456,
    iterations: 2,
    parallelism: 1,
  );

  final int memoryKib;
  final int iterations;
  final int parallelism;
}

/// Result of deriving a new vault: the KDF salt, the wrapped Data Encryption
/// Key, and the (still-live) DEK. Callers persist the salt + wrapped DEK and
/// keep the DEK only in memory.
class VaultMaterial {
  const VaultMaterial({
    required this.kdfSalt,
    required this.kdfParams,
    required this.wrappedDek,
    required this.dek,
  });

  final Uint8List kdfSalt;
  final KdfParams kdfParams;
  final EncryptedPayload wrappedDek;
  final SecretKey dek;
}

/// The core encryption boundary for the app.
///
/// Design
/// ------
/// * **KDF**: Argon2id with a per-vault random salt derives a 256-bit
///   Key Encryption Key (KEK) from the user's PIN/passphrase.
/// * **DEK**: A random 256-bit Data Encryption Key encrypts note payloads.
///   Rotating the PIN only re-wraps the DEK, so existing notes stay usable.
/// * **AEAD**: AES-GCM (256-bit) is used to wrap the DEK and to encrypt each
///   note payload. Every operation uses a fresh random 12-byte nonce.
///
/// Nothing in this class touches Drift or Flutter — it can be unit-tested in
/// isolation and reused by the future export/import codec.
class CryptoService {
  CryptoService({Random? random}) : _random = random ?? Random.secure();

  static const int _saltLength = 16;
  static const int _dekLength = 32;
  static const int _nonceLength = 12;

  final Random _random;
  final AesGcm _cipher = AesGcm.with256bits();

  // ---------------------------------------------------------------------------
  // Randomness helpers
  // ---------------------------------------------------------------------------

  Uint8List _randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  Uint8List generateSalt() => _randomBytes(_saltLength);
  Uint8List generateNonce() => _randomBytes(_nonceLength);

  // ---------------------------------------------------------------------------
  // Key derivation & DEK lifecycle
  // ---------------------------------------------------------------------------

  Argon2id _kdf(KdfParams params) => Argon2id(
        memory: params.memoryKib,
        parallelism: params.parallelism,
        iterations: params.iterations,
        hashLength: 32,
      );

  /// Derive the Key Encryption Key from the user's PIN.
  Future<SecretKey> deriveKek({
    required String pin,
    required Uint8List salt,
    KdfParams params = KdfParams.defaults,
  }) async {
    return _kdf(params).deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
  }

  /// Wrap (encrypt) the DEK with the KEK using AES-GCM.
  Future<EncryptedPayload> wrapDek({
    required SecretKey dek,
    required SecretKey kek,
  }) async {
    final dekBytes = await dek.extractBytes();
    final nonce = generateNonce();
    final box = await _cipher.encrypt(
      dekBytes,
      secretKey: kek,
      nonce: nonce,
    );
    return EncryptedPayload(
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList(box.cipherText),
      mac: Uint8List.fromList(box.mac.bytes),
    );
  }

  /// Unwrap the DEK. Throws [SecretBoxAuthenticationError] on wrong PIN.
  Future<SecretKey> unwrapDek({
    required EncryptedPayload wrapped,
    required SecretKey kek,
  }) async {
    final box = SecretBox(
      wrapped.ciphertext,
      nonce: wrapped.nonce,
      mac: Mac(wrapped.mac),
    );
    final plain = await _cipher.decrypt(box, secretKey: kek);
    return SecretKey(plain);
  }

  /// Provision a brand-new vault from a PIN. Returns everything the caller
  /// needs to persist and to start encrypting notes immediately.
  Future<VaultMaterial> createVault(
    String pin, {
    KdfParams params = KdfParams.defaults,
  }) async {
    final salt = generateSalt();
    final kek = await deriveKek(pin: pin, salt: salt, params: params);
    final dek = SecretKey(_randomBytes(_dekLength));
    final wrapped = await wrapDek(dek: dek, kek: kek);
    return VaultMaterial(
      kdfSalt: salt,
      kdfParams: params,
      wrappedDek: wrapped,
      dek: dek,
    );
  }

  // ---------------------------------------------------------------------------
  // Payload encryption (note bodies, titles, future export streams, ...)
  // ---------------------------------------------------------------------------

  Future<EncryptedPayload> encryptString(String plaintext, SecretKey dek) =>
      encryptBytes(Uint8List.fromList(utf8.encode(plaintext)), dek);

  Future<String> decryptString(EncryptedPayload payload, SecretKey dek) async {
    final bytes = await decryptBytes(payload, dek);
    return utf8.decode(bytes);
  }

  Future<EncryptedPayload> encryptBytes(
    Uint8List plaintext,
    SecretKey dek,
  ) async {
    final nonce = generateNonce();
    final box = await _cipher.encrypt(
      plaintext,
      secretKey: dek,
      nonce: nonce,
    );
    return EncryptedPayload(
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList(box.cipherText),
      mac: Uint8List.fromList(box.mac.bytes),
    );
  }

  Future<Uint8List> decryptBytes(
    EncryptedPayload payload,
    SecretKey dek,
  ) async {
    final box = SecretBox(
      payload.ciphertext,
      nonce: payload.nonce,
      mac: Mac(payload.mac),
    );
    final plain = await _cipher.decrypt(box, secretKey: dek);
    return Uint8List.fromList(plain);
  }
}
