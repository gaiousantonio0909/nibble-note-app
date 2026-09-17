import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../summarization/application/heuristic_summarization_service.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';

/// Edit a single note. Saves are debounced by simply persisting on back-nav
/// or when the user hits the save icon — the encrypted rewrite is fast, but
/// we still avoid writing on every keystroke.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Note? _current;
  bool _loaded = false;
  bool _saving = false;
  String? _summary;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    // Load the note once the notes controller is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = ref.read(notesControllerProvider);
    if (controller == null) return;
    final note = await controller.getById(widget.noteId);
    if (!mounted || note == null) return;
    setState(() {
      _current = note;
      _titleCtrl.text = note.title;
      _bodyCtrl.text = note.body;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final controller = ref.read(notesControllerProvider);
    final current = _current;
    if (controller == null || current == null) return;
    setState(() => _saving = true);
    final updated = await controller.update(
      current.copyWith(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
      ),
    );
    if (!mounted) return;
    setState(() {
      _current = updated;
      _saving = false;
    });
  }

  Future<void> _summarize() async {
    setState(() => _summarizing = true);
    final service = ref.read(summarizationServiceProvider);
    final result = await service.summarize(_bodyCtrl.text);
    if (!mounted) return;
    setState(() {
      _summary = result.isEmpty ? '(nothing to summarize yet)' : result;
      _summarizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _save();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('edit note'),
          actions: [
            IconButton(
              tooltip: 'save',
              icon: const Icon(Icons.save_outlined),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _bodyCtrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'body',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_summary != null) _SummaryCard(text: _summary!),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _summarizing ? null : _summarize,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(
                              _summarizing ? 'summarizing…' : 'summarize',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: NibblePalette.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NibblePalette.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: NibblePalette.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'on-device summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: NibblePalette.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: NibblePalette.ink)),
          ],
        ),
      ),
    );
  }
}
