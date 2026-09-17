import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// Central Drift database for Nibble Note.
///
/// * Notes are stored fully encrypted (see [Notes]).
/// * The vault row (see [Vault]) holds the wrapped Data Encryption Key.
/// * Nothing in this class touches Flutter widgets or crypto directly —
///   repositories and the [CryptoService] compose those concerns.
@DriftDatabase(tables: [Notes, Vault])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests / in-memory databases.
  AppDatabase.withExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    // `drift_flutter` picks a sensible default location (app documents dir)
    // and wires up the correct native SQLite bindings per platform.
    return driftDatabase(name: 'nibble_note');
  }
}
