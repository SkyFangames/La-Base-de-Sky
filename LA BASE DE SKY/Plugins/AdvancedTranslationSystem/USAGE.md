# Advanced Dialogue & Translation System - Usage Guide

## Table of Contents
- [Translation System](#translation-system)
  - [CSV Format](#translations-csv-format)
  - [Using Translations in Code](#using-translations-in-code)
  - [Language Detection & Selection](#language-detection--selection)
  - [Adding New Languages](#adding-new-languages)
  - [Escape Sequences](#escape-sequences)
- [Find Missing Translations Tool](#find-missing-translations-tool)

---

## Translation System

The translation system overrides the global `_INTL()` function so that every hardcoded string in the engine and plugins is looked up in `translations.csv` at runtime. Languages are fully dynamic — the system reads whatever language columns you define in the CSV header.

### Translations CSV Format

**File:** `Plugins/AdvancedTranslationSystem/translations.csv`

**Structure:**
```csv
TEXT;LANG1;LANG2;...
```

- **TEXT** — The original hardcoded string as it appears in `_INTL()` calls (case-sensitive key).
- **LANG1, LANG2, ...** — Translation columns. Use any standard language codes (ES, EN, FR, DE, IT, PT, JA, etc.).

**Example:**
```csv
TEXT;ES;EN
Continuar;Continuar;Continue
Nueva partida;Nueva partida;New Game
Opciones;Opciones;Options
¡Obtuviste {1}!;¡Obtuviste {1}!;Got {1}!
¿Quieres guardar?;¿Quieres guardar?;Do you want to save?
```

**Rules:**
- **Case-sensitive** — `"Si"`, `"SI"`, and `"Sí"` are three different keys
- **Placeholders** — Use `{1}`, `{2}`, etc. for dynamic values
- **Semicolons** — Escape with `\;` if the text contains literal semicolons
- **Newlines** — Use `\n` in the CSV to represent line breaks
- **Empty translations** — If a cell is empty, the TEXT column value is used as fallback

### Using Translations in Code

#### `_INTL()` — Automatic Translation (Recommended)
All existing Essentials code already uses `_INTL()`. The override intercepts every call:

```ruby
pbMessage(_INTL("¡Bienvenido al mundo Pokémon!"))
pbMessage(_INTL("¡Obtuviste {1}!", item_name))
pbConfirmMessage(_INTL("¿Quieres guardar?"))
```

**Lookup process:**
1. The TEXT key is matched against the first column of `translations.csv`
2. The translation for the active language column is returned
3. If the active language column is empty, the first language column is used
4. If the key isn't found in the CSV at all, the original string is returned unchanged

#### `pbTranslate()` — Alternative Name
Same functionality, different name. Useful in contexts where `_INTL` isn't available:

```ruby
pbMessage(pbTranslate("¡Bienvenido!"))
```

### Language Detection & Selection

#### Automatic Detection
On startup, the system detects the operating system language:
- **Windows:** Reads `CurrentUICulture` via PowerShell
- **Linux/macOS:** Reads `LANG`, `LANGUAGE`, or `LC_ALL` environment variables
- **Fallback:** If the OS language doesn't match any column in the CSV, the **first language column** is used

#### Manual Selection
Players can change language in the Options menu:
- **Auto** — Detect from OS (default for new games)
- **LANG1, LANG2, ...** — Each language column from the CSV header appears as an option

The setting is stored in save data (`$PokemonSystem.dialogue_language`):
- `-1` = Auto
- `0` = First language column
- `1` = Second language column
- etc.

### Adding New Languages

Simply add a column to the CSV header and fill in translations:

```csv
TEXT;ES;EN;FR
Continuar;Continuar;Continue;Continuer
Nueva partida;Nueva partida;New Game;Nouvelle partie
Opciones;Opciones;Options;Options
```

The new language automatically appears in the Options menu. No code changes needed.

### Escape Sequences

The CSV uses these escape sequences (converted to actual characters when loaded):

| Sequence | Character |
|----------|-----------|
| `\n` | Newline |
| `\t` | Tab |
| `\r` | Carriage return |
| `\"` | Double quote |
| `\'` | Single quote |
| `\\` | Backslash |
| `\;` | Semicolon (prevents splitting the CSV) |

**Example:**
```csv
TEXT;ES;EN
¿Qué debería\nhacer {1}?;¿Qué debería\nhacer {1}?;What should\n{1} do?
```

---

## Find Missing Translations Tool

**File:** `Plugins/AdvancedTranslationSystem/find_missing_translations.rb`

A standalone Ruby script that scans your entire codebase for `_INTL()` calls and reports which ones are missing from `translations.csv`.

### Running the Tool

From the project root directory:
```bash
ruby Plugins/AdvancedTranslationSystem/find_missing_translations.rb
```

### What It Does

1. **Loads existing translations** — Reads the TEXT column from `translations.csv`
2. **Scans all `.rb` files** — Searches `Plugins/` and `Data/Scripts/` for every `_INTL("...")` and `_INTL('...')` call
3. **Compares** — Case-sensitive comparison between found strings and existing CSV entries
4. **Generates report** — Creates `missing_translations.csv` with all untranslated strings

### Output

The tool prints a summary to the console:
```
Total _INTL strings found: 1523
Already in CSV:            1436
MISSING from CSV:          87
```

And generates `missing_translations.csv`:
```csv
TEXT;ES;EN
Luchar;;
Mochila;;
Pokémon;;
```

### Handling the Output

1. Open `missing_translations.csv`
2. Fill in the language columns for each entry
3. Copy the completed rows into `translations.csv`

### Features

- Handles **multi-line strings** — `_INTL("line1\nline2")` is detected correctly
- Handles **escaped quotes** — `_INTL("It's a \"test\"")` is parsed properly
- Handles **both quote styles** — Double-quoted and single-quoted strings
- **Preserves significant whitespace** — Leading/trailing spaces in keys are not stripped
- **Unescapes for comparison** — `\n` in CSV is compared against actual newlines in code
- **Shows file locations** — Each missing string shows where it was found (file:line)
