import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pet.dart';

/// Owns the pet's mood/animation state. UI reads this to drive the sprite,
/// and the note list calls [feed] whenever a note is dragged onto the pet.
class PetController extends StateNotifier<PetState> {
  PetController() : super(const PetState());

  Timer? _moodResetTimer;

  /// Trigger the "eating" mood for a moment, then return to a happy idle.
  /// Call this exactly once per note fed to the pet.
  void feed() {
    _moodResetTimer?.cancel();
    state = state.copyWith(mood: PetMood.eating, nibbles: state.nibbles + 1);
    _moodResetTimer = Timer(const Duration(milliseconds: 900), () {
      state = state.copyWith(mood: PetMood.happy);
      _moodResetTimer = Timer(const Duration(seconds: 2), () {
        state = state.copyWith(mood: PetMood.idle);
      });
    });
  }

  @override
  void dispose() {
    _moodResetTimer?.cancel();
    super.dispose();
  }
}

final petControllerProvider =
    StateNotifierProvider<PetController, PetState>((ref) => PetController());
