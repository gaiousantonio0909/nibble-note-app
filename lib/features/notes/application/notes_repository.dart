import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db/database.dart';
import '../../../data/db/tables.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../encryption/domain/encrypted_payload.dart';
import '../domain/note.dart';

/// Repository that encrypts note fields before writing them to Drift and
/// decrypts them on read. The rest of the app never touches ciphertexts.
class NotesRepository {
  NotesRepository({
    required AppDatabase db,
    required CryptoService crypto,
    required SecretKey dek,
    Uuid? uuid,
  })  : _db = db,
        _crypto = crypto,
        _dek = dek,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final CryptoService _crypto;
  final SecretKey _dek;
  final Uuid _uuid;

  /// Live stream of decrypted notes, sorted newest-updated first.
  Stream<List<Note>> watchAll() {
    final query = _db.select(_db.notes)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().asyncMap(_decryptAll);
  }

  Future<Note?> getById(String id) async {
    final row = await (_db.select(_db.notes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decryptRow(row);
  }

  Future<Note> create({required String title, required String body}) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final titlePayload = await _crypto.encryptString(title, _dek);
    final bodyPayload = await _crypto.encryptString(body, _dek);
    await _db.into(_db.notes).insert(
          NotesCompanion.insert(
            id: id,
            titleCiphertext: titlePayload.ciphertext,
            titleNonce: titlePayload.nonce,
            titleMac: titlePayload.mac,
            bodyCiphertext: bodyPayload.ciphertext,
            bodyNonce: bodyPayload.nonce,
            bodyMac: bodyPayload.mac,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return Note(
      id: id,
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Note> update(Note note) async {
    final now = DateTime.now();
    final titlePayload = await _crypto.encryptString(note.title, _dek);
    final bodyPayload = await _crypto.encryptString(note.body, _dek);
    await (_db.update(_db.notes)..where((t) => t.id.equals(note.id))).write(
      NotesCompanion(
        titleCiphertext: Value(titlePayload.ciphertext),
        titleNonce: Value(titlePayload.nonce),
        titleMac: Value(titlePayload.mac),
        bodyCiphertext: Value(bodyPayload.ciphertext),
        bodyNonce: Value(bodyPayload.nonce),
        bodyMac: Value(bodyPayload.mac),
        updatedAt: Value(now),
      ),
    );
    return note.copyWith(updatedAt: now);
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Encryption <-> Drift row translation
  // ---------------------------------------------------------------------------

  Future<List<Note>> _decryptAll(List<EncryptedNoteRow> rows) async {
    final out = <Note>[];
    for (final row in rows) {
      out.add(await _decryptRow(row));
    }
    return out;
  }

  Future<Note> _decryptRow(EncryptedNoteRow row) async {
    final title = await _crypto.decryptString(
      EncryptedPayload(
        nonce: row.titleNonce,
        ciphertext: row.titleCiphertext,
        mac: row.titleMac,
      ),
      _dek,
    );
    final body = await _crypto.decryptString(
      EncryptedPayload(
        nonce: row.bodyNonce,
        ciphertext: row.bodyCiphertext,
        mac: row.bodyMac,
      ),
      _dek,
    );
    return Note(
      id: row.id,
      title: title,
      body: body,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
