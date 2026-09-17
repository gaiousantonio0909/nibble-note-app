import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../../data/db/database.dart';
import '../../../data/db/tables.dart';
import '../domain/crypto_service.dart';
import '../domain/encrypted_payload.dart';

/// Persistence for the singleton vault row that stores the wrapped DEK
/// and the KDF parameters needed to re-derive the KEK from a PIN.
class VaultRepository {
  VaultRepository(this._db);

  final AppDatabase _db;

  static const int _rowId = 1;

  Future<VaultRow?> read() async {
    return (_db.select(_db.vault)..where((t) => t.id.equals(_rowId)))
        .getSingleOrNull();
  }

  Future<bool> exists() async => (await read()) != null;

  Future<void> write({
    required VaultMaterial material,
  }) async {
    await _db.into(_db.vault).insertOnConflictUpdate(
          VaultCompanion.insert(
            id: const Value(_rowId),
            kdfSalt: material.kdfSalt,
            kdfMemoryKib: material.kdfParams.memoryKib,
            kdfIterations: material.kdfParams.iterations,
            kdfParallelism: material.kdfParams.parallelism,
            wrappedDekCiphertext: material.wrappedDek.ciphertext,
            wrappedDekNonce: material.wrappedDek.nonce,
            wrappedDekMac: material.wrappedDek.mac,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Update *only* the wrapped-DEK columns. Used during PIN rotation where the
  /// same DEK is re-wrapped under a new KEK.
  Future<void> updateWrappedDek({
    required Uint8List salt,
    required KdfParams params,
    required EncryptedPayload wrappedDek,
  }) async {
    await (_db.update(_db.vault)..where((t) => t.id.equals(_rowId))).write(
      VaultCompanion(
        kdfSalt: Value(salt),
        kdfMemoryKib: Value(params.memoryKib),
        kdfIterations: Value(params.iterations),
        kdfParallelism: Value(params.parallelism),
        wrappedDekCiphertext: Value(wrappedDek.ciphertext),
        wrappedDekNonce: Value(wrappedDek.nonce),
        wrappedDekMac: Value(wrappedDek.mac),
      ),
    );
  }
}
