/// The MVP ships with exactly one pet and one costume, but the domain model
/// leaves room for adding more later without changing widget contracts.
enum PetCostume { defaultOutfit }

enum PetMood { idle, happy, eating }

class PetState {
  const PetState({
    this.costume = PetCostume.defaultOutfit,
    this.mood = PetMood.idle,
    this.nibbles = 0,
  });

  final PetCostume costume;
  final PetMood mood;

  /// How many notes the pet has eaten in total. Purely a fun counter for MVP;
  /// no persistence yet, but it's already scoped to the pet so future
  /// features (levels, achievements) can hang off of it.
  final int nibbles;

  PetState copyWith({
    PetCostume? costume,
    PetMood? mood,
    int? nibbles,
  }) {
    return PetState(
      costume: costume ?? this.costume,
      mood: mood ?? this.mood,
      nibbles: nibbles ?? this.nibbles,
    );
  }
}
