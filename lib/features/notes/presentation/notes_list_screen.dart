import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../encryption/application/vault_controller.dart';
import '../../pet/presentation/pet_dock.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';
import 'note_editor_screen.dart';
import 'widgets/note_tile.dart';

/// Home screen after the vault is unlocked. Shows the note list, an "add"
/// FAB, and the pixel pet dock that accepts drag-to-feed deletes.
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesStreamProvider);
    final controller = ref.watch(notesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('my notes'),
        actions: [
          IconButton(
            tooltip: 'lock vault',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(vaultControllerProvider.notifier).lock(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller == null
            ? null
            : () async {
                final note = await controller.create();
                if (!context.mounted) return;
                await _openEditor(context, note);
              },
        icon: const Icon(Icons.add),
        label: const Text('new note'),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load notes: $e'),
          ),
        ),
        data: (notes) => _NotesBody(
          notes: notes,
          onOpen: (n) => _openEditor(context, n),
          onDelete: (n) async {
            await controller?.delete(n.id);
          },
          onFed: (n) async {
            // Feeding the pet is just a themed delete.
            await controller?.delete(n.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: NibblePalette.primary,
                  content: Text('nom nom! note eaten 🍪'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, Note note) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: note.id),
      ),
    );
  }
}

class _NotesBody extends StatelessWidget {
  const _NotesBody({
    required this.notes,
    required this.onOpen,
    required this.onDelete,
    required this.onFed,
  });

  final List<Note> notes;
  final void Function(Note) onOpen;
  final Future<void> Function(Note) onDelete;
  final Future<void> Function(Note) onFed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return NoteTile(
                      note: note,
                      onTap: () => onOpen(note),
                      onDelete: () => onDelete(note),
                    );
                  },
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: NibblePalette.ink, width: 2),
            ),
            color: NibblePalette.surface,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: PetDock(onNoteFed: onFed)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 56, color: NibblePalette.primary),
            SizedBox(height: 12),
            Text(
              'no notes yet.\ntap "new note" to write one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: NibblePalette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
