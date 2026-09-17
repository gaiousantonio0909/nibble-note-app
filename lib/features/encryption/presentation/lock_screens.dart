import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pixel_theme.dart';
import '../application/vault_controller.dart';
import '../domain/vault_state.dart';

/// First-run screen. Asks the user to pick a PIN (min 4 chars) that will
/// protect the vault. The PIN never leaves the device.
class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text;
    if (pin != _confirmCtrl.text) {
      setState(() => _localError = "PINs don't match");
      return;
    }
    setState(() => _localError = null);
    await ref.read(vaultControllerProvider.notifier).setupVault(pin);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('welcome to nibble note')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: NibblePalette.primary,
                  size: 56,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pick a PIN to protect your notes.\n'
                  'It never leaves this device — but if you forget it, '
                  'your notes cannot be recovered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NibblePalette.inkSoft),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(labelText: 'New PIN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Confirm PIN'),
                ),
                if (_localError != null || state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _localError ?? state.errorMessage ?? '',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.isBusy ? null : _submit,
                  child: Text(state.isBusy ? '...' : 'create vault'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown whenever the vault is locked. On success the app switches to the
/// notes list.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(vaultControllerProvider.notifier).unlock(_pinCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('nibble note')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.pets,
                  color: NibblePalette.primary,
                  size: 56,
                ),
                const SizedBox(height: 12),
                const Text(
                  'welcome back!\nenter your PIN to unlock your notes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NibblePalette.inkSoft),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  autofocus: true,
                  keyboardType: TextInputType.visiblePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.isBusy ? null : _submit,
                  child: Text(state.isBusy ? '...' : 'unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
