import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../domain/crypto_service.dart';
import '../domain/encrypted_payload.dart';
import '../domain/vault_state.dart';
import 'vault_repository.dart';

/// Riverpod-managed lifecycle for the encryption vault:
/// setup → unlock → (locked | unlocked) → optional PIN rotation.
class VaultController extends StateNotifier<VaultState> {
  VaultController({
    required CryptoService crypto,
    required VaultRepository repo,
  })  : _crypto = crypto,
        _repo = repo,
        super(const VaultState.loading()) {
    // Fire-and-forget initial check; UI stays in "loading" until it completes.
    // ignore: unawaited_futures
    _bootstrap();
  }

  final CryptoService _crypto;
  final VaultRepository _repo;

  Future<void> _bootstrap() async {
    final exists = await _repo.exists();
    state = VaultState(
      status: exists ? VaultStatus.locked : VaultStatus.needsSetup,
    );
  }

  // ---------------------------------------------------------------------------
  // First-run setup
  // ---------------------------------------------------------------------------

  /// Create a brand new vault protected by [pin]. Leaves the app unlocked.
  Future<void> setupVault(String pin) async {
    if (pin.length < 4) {
      state = state.copyWith(errorMessage: 'PIN must be at least 4 characters');
      return;
    }
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final material = await _crypto.createVault(pin);
      await _repo.write(material: material);
      state = VaultState(
        status: VaultStatus.unlocked,
        dek: material.dek,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Could not create vault: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Unlock / lock
  // ---------------------------------------------------------------------------

  Future<void> unlock(String pin) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final row = await _repo.read();
    if (row == null) {
      state = const VaultState(status: VaultStatus.needsSetup);
      return;
    }
    try {
      final kek = await _crypto.deriveKek(
        pin: pin,
        salt: row.kdfSalt,
        params: KdfParams(
          memoryKib: row.kdfMemoryKib,
          iterations: row.kdfIterations,
          parallelism: row.kdfParallelism,
        ),
      );
      final dek = await _crypto.unwrapDek(
        wrapped: EncryptedPayload(
          nonce: row.wrappedDekNonce,
          ciphertext: row.wrappedDekCiphertext,
          mac: row.wrappedDekMac,
        ),
        kek: kek,
      );
      state = VaultState(status: VaultStatus.unlocked, dek: dek);
    } on SecretBoxAuthenticationError {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Wrong PIN. Try again.',
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unlock failed: $e',
      );
    }
  }

  /// Drop the DEK from memory and return to the locked screen.
  void lock() {
    state = const VaultState(status: VaultStatus.locked);
  }
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(ref.watch(appDatabaseProvider)),
);

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultState>((ref) {
  return VaultController(
    crypto: ref.watch(cryptoServiceProvider),
    repo: ref.watch(vaultRepositoryProvider),
  );
});
