# CLAUDE.md — guidance for AI code assistants working on Nibble Note

This file exists so tools like Claude Code, Copilot, etc. can get up to speed
on Nibble Note quickly without re-deriving the architecture from scratch.

## What this app is

**Nibble Note** is a local-first, privacy-first note-taking Flutter app with a
cute pixel pet you can feed notes to. Everything runs on-device:

- Notes are stored in a local SQLite database via **Drift**.
- Note contents are **encrypted at rest** with AES-GCM using a Data Encryption
  Key (DEK) that is itself wrapped by a Key Encryption Key derived from the
  user's PIN via Argon2id.
- Summarization is designed to run on-device. The MVP ships an extractive
  placeholder; the interface is stable for swapping in a real on-device LLM.
- There is exactly **one** pet and **one** costume in the MVP.

## Tech stack (canonical)

- **Flutter** (>=3.19)
- **Riverpod** (`flutter_riverpod`) for all app / feature state
- **Drift** for local persistence (`drift`, `drift_flutter`, `sqlite3_flutter_libs`)
- **cryptography** package for Argon2id + AES-GCM
- **flutter_secure_storage** available for future OS-level secret storage
  (biometric-wrapped keys, remember-me tokens); not required by the MVP.

Do **not** add cloud SDKs, telemetry, remote logging, or online summarization
providers. This app must work fully offline.

## Directory layout

```
lib/
├── main.dart               ← runApp(ProviderScope(NibbleNoteApp))
├── shell/
│   └── root_gate.dart      ← routes between setup / lock / notes based on vault state
├── core/
│   └── theme/              ← palette + ThemeData
├── data/
│   └── db/                 ← Drift database + tables (nothing UI-aware)
└── features/
    ├── encryption/         ← CryptoService, vault repo/controller, lock screens
    ├── notes/              ← Note model, NotesRepository, NotesController, list & editor
    ├── pet/                ← Pet state, PixelPet CustomPainter sprite, PetDock drop target
    └── summarization/      ← SummarizationService interface + heuristic placeholder
```

Each feature follows a `domain / application / presentation` split. Cross-
feature wiring happens in `shell/` and top-level providers.

## Encryption model (must-know)

```
PIN ──Argon2id(salt, params)──▶ KEK
                                 │
                             AES-GCM
                                 │
                     wrapped DEK  ◀── DEK (random 256-bit)
                                 │
                             AES-GCM
                                 │
              note {title, body} ◀── plaintext
```

Rules for AI editors:

1. **Never** log, print, or expose plaintext note contents, PINs, or the DEK.
2. **Never** persist the DEK to disk. It only lives in the `VaultState.dek`
   field in memory while the vault is unlocked.
3. Every AES-GCM operation must use a **fresh random 12-byte nonce**.
   Reuse breaks the whole scheme. The helper for this is
   `CryptoService.generateNonce()`.
4. Prefer `authenticated encryption` (AES-GCM / XChaCha20-Poly1305). Never
   introduce raw AES-CBC / ECB / CTR without a MAC.
5. If you rotate the KDF parameters, keep the old parameters readable — the
   vault row records the memory/iterations/parallelism used at write time so
   older vaults still unlock.
6. Do not add "recover forgotten PIN" flows without an explicit product
   decision. The current design is _intentionally_ unrecoverable if the PIN
   is lost.

## State management conventions

- All shared state goes through Riverpod providers. Don't reintroduce
  `InheritedWidget` / `Provider` / singletons.
- Providers that depend on the DEK (like `notesRepositoryProvider`) return
  `null` when the vault is locked. Widgets must handle that null.
- Controllers are `StateNotifier`s. Mutating methods must never expose the
  DEK back to the UI.

## Drift conventions

- Column definitions live in `data/db/tables.dart`.
- `AppDatabase` is generated via `drift_dev`. After changing tables, run:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- Never store plaintext user content in Drift columns. Only ciphertext +
  nonce + MAC + timestamps.

## Pet conventions

- Exactly one pet, one costume in the MVP. If new pets/costumes are added,
  extend `PetCostume` / add a new drawer method — do not fork the widget.
- The pet is drawn with a `CustomPainter` operating on a 16×16 pixel grid.
  Keep the sprite readable at 96px; snap paint calls to integer pixels.
- Feeding a note = deleting it. `PetController.feed()` handles the mood
  transition; `NotesController.delete()` handles persistence. Keep them
  decoupled.

## Summarization conventions

- The public boundary is `SummarizationService`. Implementations must be
  fully on-device.
- Do **not** send note content to a remote API to summarize. This is a
  privacy-first app.
- To wire in a real on-device model, add a new `SummarizationService`
  implementation and override `summarizationServiceProvider`. Do not modify
  the widget layer.

## Testing

- Unit tests live in `test/`. There are round-trip tests for the crypto
  layer (`test/crypto_service_test.dart`) and the summarizer
  (`test/summarization_test.dart`). Add tests alongside new pure Dart
  logic; widgets can be exercised with `flutter_test`'s `WidgetTester`.
- Argon2id at production parameters is slow; tests use a lighter
  `KdfParams(memoryKib: 4096, iterations: 1, parallelism: 1)` — real code
  paths always use `KdfParams.defaults`.

## Commands cheat sheet

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## Explicit non-goals (do not add these to MVP)

- Cloud sync, accounts, or any remote backend.
- Multiple pets, multiple costumes, shop, currency, room decoration.
- Multi-device features, sharing, social features.
- Online summarization / online AI providers.
