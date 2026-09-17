import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/encryption/application/vault_controller.dart';
import '../features/encryption/domain/vault_state.dart';
import '../features/encryption/presentation/lock_screens.dart';
import '../features/notes/presentation/notes_list_screen.dart';

/// Routes the app between setup / lock / notes based on [VaultState].
///
/// This is deliberately not a full router (no deep-linking in the MVP) —
/// there are only three top-level destinations and they're driven entirely
/// by the vault status.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultControllerProvider);
    switch (vault.status) {
      case VaultStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case VaultStatus.needsSetup:
        return const SetupPinScreen();
      case VaultStatus.locked:
        return const UnlockScreen();
      case VaultStatus.unlocked:
        return const NotesListScreen();
    }
  }
}
