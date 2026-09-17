import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../encryption/application/vault_controller.dart';
import '../../encryption/domain/vault_state.dart';
import '../domain/note.dart';
import 'notes_repository.dart';

/// A repository that only exists while the vault is unlocked. It is rebuilt
/// automatically whenever the DEK changes (unlock/lock/rotate).
final notesRepositoryProvider = Provider<NotesRepository?>((ref) {
  final vault = ref.watch(vaultControllerProvider);
  if (vault.status != VaultStatus.unlocked || vault.dek == null) {
    return null;
  }
  return NotesRepository(
    db: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    dek: vault.dek as SecretKey,
  );
});

/// Live list of decrypted notes. Emits an empty list while the vault is
/// locked so the list UI can safely `.when()` on it without null-checks.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return Stream<List<Note>>.value(const []);
  return repo.watchAll();
});

/// Thin controller that groups the mutating operations behind a single
/// object the UI can call. Keeps widgets from touching the repository
/// directly.
class NotesController {
  NotesController(this._repo);
  final NotesRepository _repo;

  Future<Note> create({String title = '', String body = ''}) =>
      _repo.create(title: title, body: body);

  Future<Note> update(Note note) => _repo.update(note);

  Future<void> delete(String id) => _repo.delete(id);

  Future<Note?> getById(String id) => _repo.getById(id);
}

final notesControllerProvider = Provider<NotesController?>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return null;
  return NotesController(repo);
});
