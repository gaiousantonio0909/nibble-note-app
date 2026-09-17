import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/pixel_theme.dart';
import '../../domain/note.dart';

/// A single note card in the list. Also acts as the drag source that feeds
/// the pixel pet when dropped on the [PetDock].
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.MMMd().add_jm();
    final preview = note.body.isEmpty
        ? '(empty note)'
        : note.body.replaceAll(RegExp(r'\s+'), ' ');

    final tile = Card(
      elevation: 0,
      color: NibblePalette.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NibblePalette.ink, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? '(untitled)' : note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: NibblePalette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NibblePalette.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFmt.format(note.updatedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: NibblePalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'delete',
                icon: const Icon(Icons.delete_outline),
                color: NibblePalette.primaryDark,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );

    final ghost = Opacity(
      opacity: 0.85,
      child: SizedBox(width: 260, child: tile),
    );

    return LongPressDraggable<Note>(
      data: note,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(color: Colors.transparent, child: ghost),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}
