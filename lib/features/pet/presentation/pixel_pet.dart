import 'package:flutter/material.dart';

import '../../../core/theme/pixel_theme.dart';
import '../domain/pet.dart';

/// A hand-drawn pixel-art pet. The whole sprite is a 16×16 grid painted with
/// [CustomPainter] so we don't need to ship image assets in the MVP.
///
/// The sprite reacts to [mood]:
///  * [PetMood.idle]   — closed relaxed mouth
///  * [PetMood.happy]  — open smile, sparkle cheeks
///  * [PetMood.eating] — wide mouth + chomp lines
class PixelPet extends StatelessWidget {
  const PixelPet({
    super.key,
    required this.mood,
    required this.costume,
    this.size = 160,
  });

  final PetMood mood;
  final PetCostume costume;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PetPainter(mood: mood, costume: costume),
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({required this.mood, required this.costume});

  final PetMood mood;
  final PetCostume costume;

  static const int _gridSize = 16;

  /// Each character maps to a color:
  ///   '.' transparent, 'k' outline, 'b' body, 's' shade, 'e' belly,
  ///   'y' eye, 'p' blush, 'h' costume (hat/bow), 'm' mouth
  ///
  /// The base sprite is a rounded chubby blob; per-mood overlays tweak the
  /// mouth row.
  List<String> _spriteRows() {
    return const [
      '................',
      '................',
      '.....hhhhhh.....', // costume: little chef hat brim
      '....hhhhhhhh....',
      '....kbbbbbbk....',
      '...kbbbbbbbbk...',
      '..kbbeeeebbbbk..',
      '..kbyeeeebybbk..', // eyes
      '..kbbeeeebbbbk..',
      '..kbppeeeeppbk..', // blush
      '..kbbbMMMMbbbk..', // mouth row (mood overlays this)
      '...kbbbbbbbbk...',
      '...kbsssssssk...', // shaded feet band
      '....kkkkkkkk....',
      '................',
      '................',
    ];
  }

  Color _colorFor(String c) {
    switch (c) {
      case 'k':
        return NibblePalette.ink;
      case 'b':
        return NibblePalette.petBody;
      case 's':
        return NibblePalette.petShade;
      case 'e':
        return NibblePalette.petBelly;
      case 'y':
        return NibblePalette.petEye;
      case 'p':
        return NibblePalette.petBlush;
      case 'h':
        return NibblePalette.costumeHat;
      case 'M':
        return _mouthColor();
      default:
        return const Color(0x00000000);
    }
  }

  Color _mouthColor() {
    switch (mood) {
      case PetMood.eating:
        return NibblePalette.primaryDark;
      case PetMood.happy:
        return NibblePalette.primary;
      case PetMood.idle:
        return NibblePalette.ink;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = _spriteRows();
    final pixel = size.width / _gridSize;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var y = 0; y < _gridSize; y++) {
      final row = rows[y];
      for (var x = 0; x < _gridSize; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        paint.color = _colorFor(ch);
        canvas.drawRect(
          Rect.fromLTWH(x * pixel, y * pixel, pixel, pixel),
          paint,
        );
      }
    }

    // Mouth overlay: replace the 'M' band per mood so the base grid stays flat.
    _paintMouthOverlay(canvas, pixel);

    // Chomp sparkles while eating.
    if (mood == PetMood.eating) {
      final sparkle = Paint()..color = NibblePalette.accent;
      _pixel(canvas, sparkle, pixel, 1, 6);
      _pixel(canvas, sparkle, pixel, 14, 7);
      _pixel(canvas, sparkle, pixel, 2, 9);
      _pixel(canvas, sparkle, pixel, 13, 10);
    }
  }

  void _paintMouthOverlay(Canvas canvas, double pixel) {
    final mouth = Paint()..color = _mouthColor();
    final body = Paint()..color = NibblePalette.petBody;

    // Clear the mouth band back to body first (row 10 cols 6..9).
    for (var x = 6; x <= 9; x++) {
      _pixel(canvas, body, pixel, x, 10);
    }

    switch (mood) {
      case PetMood.idle:
        _pixel(canvas, mouth, pixel, 7, 10);
        _pixel(canvas, mouth, pixel, 8, 10);
        break;
      case PetMood.happy:
        _pixel(canvas, mouth, pixel, 6, 10);
        _pixel(canvas, mouth, pixel, 7, 10);
        _pixel(canvas, mouth, pixel, 8, 10);
        _pixel(canvas, mouth, pixel, 9, 10);
        _pixel(canvas, mouth, pixel, 5, 9);
        _pixel(canvas, mouth, pixel, 10, 9);
        break;
      case PetMood.eating:
        // Big open mouth (2 rows).
        for (var x = 6; x <= 9; x++) {
          _pixel(canvas, mouth, pixel, x, 9);
          _pixel(canvas, mouth, pixel, x, 10);
        }
        break;
    }
  }

  void _pixel(Canvas c, Paint p, double px, int gx, int gy) {
    c.drawRect(Rect.fromLTWH(gx * px, gy * px, px, px), p);
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) =>
      old.mood != mood || old.costume != costume;
}
