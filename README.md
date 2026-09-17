# 🐹 Nibble Note

A **local-first, privacy-first** Flutter note-taking app with a cute pixel
pet you can feed notes to.

- ✍️ Take notes.
- 🔒 They're encrypted on-device with AES-GCM + Argon2id — even the database
  file sees only ciphertext.
- 🐹 Drag a note onto the pet to feed (delete) it with a cute chomp
  animation.
- 🧠 Summarize a note on-device with the built-in placeholder summarizer
  (swap in a real on-device LLM later without touching the UI).

> This is the MVP: **one pet, one costume, no cloud, no accounts.**

---

## ✨ Features

| Area | What's in the MVP |
| --- | --- |
| Notes | Create, edit, list, delete |
| Encryption | Argon2id-derived KEK wraps a random 256-bit DEK; AES-GCM for all note payloads |
| Lock flow | Set-PIN onboarding, unlock-with-PIN screen, manual lock from the notes screen |
| Pet | One pixel-art pet, one costume, drag-note-to-feed with an "eating" animation |
| Summarization | On-device `SummarizationService` interface + heuristic placeholder implementation |

Explicit non-goals for the MVP: cloud sync, accounts, multiplayer, shop,
multiple pets, multiple costumes, room decoration. See `CLAUDE.md`.

---

## 🏗️ Architecture

```
lib/
├── main.dart                    ← ProviderScope + NibbleNoteApp
├── shell/root_gate.dart         ← chooses setup / lock / notes screen
├── core/theme/                  ← palette + Material theme
├── data/db/                     ← Drift database + encrypted tables
└── features/
    ├── encryption/              ← CryptoService, vault repo/controller, lock screens
    ├── notes/                   ← Note domain, repository, controller, list + editor UI
    ├── pet/                     ← Pet state, PixelPet painter, PetDock drop target
    └── summarization/           ← Service interface + heuristic on-device placeholder
```

Every feature is split into `domain / application / presentation` so the
encryption layer can be unit-tested and swapped without touching the UI or
persistence layer.

### Encryption at rest

```
PIN ──Argon2id(salt)──▶ KEK ──AES-GCM──▶ wraps ──▶ DEK ──AES-GCM──▶ note payload
```

- **KDF**: Argon2id (defaults: 19 MiB, 2 iterations, p=1 — OWASP 2023 baseline).
- **DEK**: random 256-bit, generated once at vault creation, kept only in
  memory while unlocked, wrapped by the KEK on disk.
- **AEAD**: AES-GCM with a fresh random 12-byte nonce on every write. The
  database stores `{ciphertext, nonce, mac}` for every encrypted field.
- **Rotation-ready**: KDF parameters are stored per-vault, so upgrading to
  stronger params doesn't invalidate existing vaults.
- **Export-ready**: the on-disk envelope (`EncryptedPayload`) is a plain data
  class — the same shape drives future encrypted export/import.

The full design and rules for editing it live in [`CLAUDE.md`](./CLAUDE.md).

### State management

Riverpod providers own everything:

- `vaultControllerProvider` — vault lifecycle (setup / lock / unlock)
- `appDatabaseProvider` — the Drift database
- `notesRepositoryProvider` / `notesControllerProvider` — only exist while
  unlocked; automatically rebuild when the DEK changes
- `notesStreamProvider` — decrypted stream for the list
- `petControllerProvider` — pet mood/animation state
- `summarizationServiceProvider` — the on-device summarizer (override this
  to plug in a real local LLM later)

---

## 🚀 Getting started

### Prerequisites

- Flutter **3.19+** (Dart **3.3+**)
- A device or simulator/emulator (Android, iOS, macOS, Linux, Windows).
  Drift's native SQLite bindings are pulled in via `sqlite3_flutter_libs`.

### Install & generate

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Generate the Drift database code (creates lib/data/db/database.g.dart)
dart run build_runner build --delete-conflicting-outputs
```

> ℹ️ The `*.g.dart` files are git-ignored on purpose — always regenerate
> them locally after cloning or after changing anything in
> `lib/data/db/tables.dart`.

### Run

```bash
flutter run
```

On first launch you'll be asked to pick a PIN. The PIN never leaves the
device and cannot be recovered if lost.

### Test

```bash
flutter test
```

The suite includes:

- `test/crypto_service_test.dart` — end-to-end encryption round-trip,
  wrong-PIN rejection, and nonce randomness.
- `test/summarization_test.dart` — sanity checks for the heuristic summarizer.

### Lint

```bash
flutter analyze
```

---

## 🧠 Wiring in a real on-device LLM later

The summarization service is an interface:

```dart
abstract class SummarizationService {
  Future<String> summarize(String content);
}
```

To swap in a real on-device model (e.g. `flutter_gemma`, `llama.cpp`
bindings, or a TFLite text model):

1. Implement `SummarizationService` in your new class.
2. Override the provider at app start:

   ```dart
   ProviderScope(
     overrides: [
       summarizationServiceProvider.overrideWithValue(MyGemmaSummarizer()),
     ],
     child: const NibbleNoteApp(),
   );
   ```

The UI in `NoteEditorScreen` never has to change.

---

## 🐾 Feeding the pet

1. Long-press a note in the list.
2. Drag it down onto the pet in the dock.
3. Drop — the pet chomps, and the note is deleted from the encrypted store.

Feeding is just a delete with personality. The pet is drawn with
`CustomPainter` on a 16×16 pixel grid, so no image assets ship with the app.

---

## 📄 Files worth reading first

- [`CLAUDE.md`](./CLAUDE.md) — architecture, encryption rules, and hard
  constraints for AI/human editors.
- `lib/features/encryption/domain/crypto_service.dart` — the entire
  encryption boundary.
- `lib/features/pet/presentation/pixel_pet.dart` — the pixel-art sprite
  painter.

---

## 🛡️ Threat model (short version)

- **Assumes**: the OS keeps app storage private to the app. A cold device
  seized without the PIN cannot yield plaintext notes.
- **Does not defend against**: attackers with the running device unlocked,
  compromised OS/keyboard, or a user who forgets their PIN (there is no
  recovery — by design).

---

## License

TBD.
