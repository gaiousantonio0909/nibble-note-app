import 'package:flutter_test/flutter_test.dart';
import 'package:nibble_note/features/encryption/domain/crypto_service.dart';

void main() {
  // Argon2id with defaults is real work; use a lighter profile for tests so
  // they finish quickly on CI. The scheme is identical either way.
  const testParams = KdfParams(memoryKib: 4096, iterations: 1, parallelism: 1);
  final crypto = CryptoService();

  group('CryptoService', () {
    test('round-trips a note payload with the DEK', () async {
      final material = await crypto.createVault('correct horse', params: testParams);

      final payload = await crypto.encryptString(
        'hello nibble, this is a secret 🐹',
        material.dek,
      );

      final plaintext = await crypto.decryptString(payload, material.dek);
      expect(plaintext, 'hello nibble, this is a secret 🐹');
    });

    test('unwraps DEK with the correct PIN', () async {
      final material = await crypto.createVault('open sesame', params: testParams);

      final kek = await crypto.deriveKek(
        pin: 'open sesame',
        salt: material.kdfSalt,
        params: testParams,
      );
      final dek = await crypto.unwrapDek(wrapped: material.wrappedDek, kek: kek);

      final payload = await crypto.encryptString('secret', material.dek);
      final decrypted = await crypto.decryptString(payload, dek);
      expect(decrypted, 'secret');
    });

    test('wrong PIN cannot unwrap DEK', () async {
      final material = await crypto.createVault('right pin', params: testParams);

      final wrongKek = await crypto.deriveKek(
        pin: 'wrong pin',
        salt: material.kdfSalt,
        params: testParams,
      );
      await expectLater(
        crypto.unwrapDek(wrapped: material.wrappedDek, kek: wrongKek),
        throwsA(anything),
      );
    });

    test('same plaintext produces different ciphertext (nonce randomness)',
        () async {
      final material = await crypto.createVault('pin', params: testParams);
      final a = await crypto.encryptString('same', material.dek);
      final b = await crypto.encryptString('same', material.dek);
      expect(a.ciphertext, isNot(equals(b.ciphertext)));
      expect(a.nonce, isNot(equals(b.nonce)));
    });
  });
}
