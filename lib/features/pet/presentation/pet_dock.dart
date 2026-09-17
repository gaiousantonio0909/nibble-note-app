import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../notes/domain/note.dart';
import '../application/pet_controller.dart';
import '../domain/pet.dart';
import 'pixel_pet.dart';

/// A docked pixel pet that also acts as a drop target for [Note] drags.
///
/// When a note is dragged over the pet, it wobbles and lights up. When
/// dropped, [onNoteFed] is called (the notes controller uses this to delete
/// the note) and a short chomp animation plays.
class PetDock extends ConsumerStatefulWidget {
  const PetDock({
    super.key,
    required this.onNoteFed,
  });

  final Future<void> Function(Note note) onNoteFed;

  @override
  ConsumerState<PetDock> createState() => _PetDockState();
}

class _PetDockState extends ConsumerState<PetDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petControllerProvider);
    final controller = ref.read(petControllerProvider.notifier);

    return DragTarget<Note>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) async {
        setState(() => _hovering = false);
        controller.feed();
        await widget.onNoteFed(details.data);
      },
      builder: (context, candidate, rejected) {
        final scale = _hovering || pet.mood == PetMood.eating ? 1.08 : 1.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovering
                ? NibblePalette.accent.withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovering ? NibblePalette.primaryDark : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _wobble,
                builder: (context, child) {
                  final tilt = pet.mood == PetMood.eating
                      ? 0.0
                      : (_wobble.value - 0.5) * 0.05;
                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(angle: tilt, child: child),
                  );
                },
                child: PixelPet(
                  mood: pet.mood,
                  costume: pet.costume,
                  size: 120,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(pet),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NibblePalette.inkSoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _label(PetState pet) {
    if (_hovering) return 'yum?';
    switch (pet.mood) {
      case PetMood.eating:
        return 'nom nom!';
      case PetMood.happy:
        return 'thanks!';
      case PetMood.idle:
        return pet.nibbles == 0
            ? 'drag a note to feed me'
            : 'nibbles: ${pet.nibbles}';
    }
  }
}
