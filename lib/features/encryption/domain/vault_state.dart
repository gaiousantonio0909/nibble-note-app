import 'package:cryptography/cryptography.dart';

import 'crypto_service.dart';

/// Where the app currently sits in the lock/unlock lifecycle.
enum VaultStatus {
  /// We haven't checked the database yet.
  loading,

  /// No vault row exists. Show the "Set a PIN" onboarding screen.
  needsSetup,

  /// A vault exists but is locked. Show the unlock screen.
  locked,

  /// The DEK is loaded in memory. Notes screens are usable.
  unlocked,
}

/// Immutable snapshot of vault state exposed to the UI.
class VaultState {
  const VaultState({
    required this.status,
    this.dek,
    this.errorMessage,
    this.isBusy = false,
  });

  const VaultState.loading() : this(status: VaultStatus.loading);

  final VaultStatus status;

  /// Only present while [status] is [VaultStatus.unlocked]. Never persisted.
  final SecretKey? dek;

  /// Human-facing error from the last operation, if any (e.g. wrong PIN).
  final String? errorMessage;

  /// True while an async op (unlock, setup, rotation) is in flight.
  final bool isBusy;

  VaultState copyWith({
    VaultStatus? status,
    SecretKey? dek,
    Object? errorMessage = _sentinel,
    bool? isBusy,
  }) {
    return VaultState(
      status: status ?? this.status,
      dek: dek ?? this.dek,
      errorMessage:
          identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  static const Object _sentinel = Object();
}
