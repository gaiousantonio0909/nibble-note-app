/// Plaintext domain model for a note.
///
/// Instances of this class only exist after the vault is unlocked and the DEK
/// is in memory. Persistence layer never sees these fields in the clear.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
