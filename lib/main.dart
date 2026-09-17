import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/pixel_theme.dart';
import 'shell/root_gate.dart';

class NibbleNoteApp extends StatelessWidget {
  const NibbleNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nibble Note',
      debugShowCheckedModeBanner: false,
      theme: buildNibbleTheme(),
      home: const RootGate(),
    );
  }
}

void main() {
  runApp(const ProviderScope(child: NibbleNoteApp()));
}
