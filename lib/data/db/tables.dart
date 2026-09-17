import 'package:drift/drift.dart';

/// Notes are stored in fully-encrypted form. The database sees only random
/// bytes — title, body, nonces and GCM tags. Timestamps are kept in plaintext
/// so lists can be sorted without unlocking the vault (but no user content
/// leaks through them).
@DataClassName('EncryptedNoteRow')
class Notes extends Table {
  TextColumn get id => text()();

  // Encrypted title
  BlobColumn get titleCiphertext => blob()();
  BlobColumn get titleNonce => blob()();
  BlobColumn get titleMac => blob()();

  // Encrypted body
  BlobColumn get bodyCiphertext => blob()();
  BlobColumn get bodyNonce => blob()();
  BlobColumn get bodyMac => blob()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Singleton row (id = 1) holding the wrapped Data Encryption Key and the KDF
/// parameters used to derive its Key Encryption Key. Without knowing the PIN,
/// this row is useless — but knowing the PIN plus this row is enough to
/// decrypt every note.
@DataClassName('VaultRow')
class Vault extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  BlobColumn get kdfSalt => blob()();
  IntColumn get kdfMemoryKib => integer()();
  IntColumn get kdfIterations => integer()();
  IntColumn get kdfParallelism => integer()();

  BlobColumn get wrappedDekCiphertext => blob()();
  BlobColumn get wrappedDekNonce => blob()();
  BlobColumn get wrappedDekMac => blob()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
