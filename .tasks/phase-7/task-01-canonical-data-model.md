---
id: task-01
title: Canonical data model in WordManager (schema + starter variants + helpers)
status: done
complexity: medium
blocked-by: []
---

## Goal

Migrate `WordManager.master_list` from a flat `Array[String]` to a list
of canonical entries with typo and synonym pools. Add the two helper
functions (`canonicalize`, `display_variants`) that everything else in
the phase depends on. Author starter variants for all 28 existing
entries (1–2 typos + 1–2 synonyms each) so the game runs end-to-end
after this task.

After this task: no gameplay change yet — `_pick_document_word_pool`
and `_roll_toilet_intel` still consume strings via the wrapper helpers
below. Tasks 02 and 03 cut the rest of the codebase over to canonicals.

## Context

Current shape in `potty-secret/WordManager.gd:56-64`:

```gdscript
var master_list: Array[String] = [
    "aliens", "Elvis", "bigfoot", ...
]
```

Other readers of `master_list`:

- `WordManager.pick_random_words(count)` — `WordManager.gd:11`. Shuffles a
  duplicate and returns the first N strings. Used by `_roll_toilet_intel`
  in `game2.gd:303`.
- `WordManager.get_next_batch(count)` / `_refill_queue()` — `WordManager.gd:20-32`.
  Queue-based draw, used nowhere in `game2.gd` (likely vestigial from the
  old paper.gd flow). Leave intact for now but it must consume the new
  shape correctly.
- `game2.gd:_single_token_master_words()` — `game2.gd:149-154`. Filters out
  multi-word entries. Used by `_pick_document_word_pool` for paper word
  selection.

Design spec section: "Data model" in
`potty-secret/docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md`.

## Acceptance Criteria

- [x] In `potty-secret/WordManager.gd`, add a VariantMode enum at the top of the class body (before `master_list`):

  ```gdscript
  enum VariantMode { CANONICAL, TYPO, SYNONYM, TYPO_OR_SYNONYM }
  ```

- [x] Replace `master_list: Array[String]` with `master_list: Array[Dictionary]`. Each entry must have keys `canonical: String`, `typos: Array[String]`, `synonyms: Array[String]`. Author all 28 existing entries with starter content. Use the existing string as the canonical (uppercased for display consistency with current intel rendering — verify by checking `toilet_msg.gd` / `toilet_msg.tscn` for how labels are cased; if they're rendered as-is, keep the original case). Suggested starter variants (1–2 of each kind per canonical) — the implementer should author with care for the "typewriter clerk" aesthetic; examples:

  - `{canonical: "aliens", typos: ["allens", "aloiens"], synonyms: ["them", "outsiders"]}`
  - `{canonical: "Elvis", typos: ["Evlis", "Elviss"], synonyms: ["the King"]}`
  - `{canonical: "bigfoot", typos: ["bigfooot", "bifoot"], synonyms: ["sasquatch"]}`
  - `{canonical: "Roswell", typos: ["Rosswell", "Roswel"], synonyms: ["the crash"]}`

  Typos must be plausible single-character typewriter slips (adjacent-key swap, doubled letter, missed letter, transposition). Synonyms must be reasonable substitutes a clerk would write in place of the canonical. Multi-word canonicals (e.g. "Big Secret", "Area 51", "New World Order") may use a single-word synonym in the synonym pool but do NOT need typos that span the space.

- [x] Add `func canonicalize(word: String) -> String`:
  - Normalizes input by lowercasing and stripping non-alphanumerics (re-use the same logic as `text_renderer.gd._normalize_word`, but inline here — don't reach into `text_renderer` from `WordManager`).
  - For each entry in `master_list`, checks normalized-canonical, normalized-typos, normalized-synonyms.
  - Returns the entry's canonical string (in its authored case) on match.
  - Returns `""` if no entry matches.

- [x] Add `func display_variants(canonical: String, mode: VariantMode) -> Array[String]`:
  - Finds the entry matching `canonical` (case-sensitive on the canonical field).
  - Returns variant pool by mode:
    - `CANONICAL`: `[canonical]`
    - `TYPO`: `typos` (or `[canonical]` if `typos` is empty as fallback)
    - `SYNONYM`: `synonyms` (or `[canonical]` if `synonyms` is empty as fallback)
    - `TYPO_OR_SYNONYM`: `typos + synonyms` (or `[canonical]` if both empty)
  - Returns `[]` if canonical isn't found at all (programmer error — should not happen at runtime).

- [x] Add `func pick_random_canonicals(count: int) -> Array[String]`:
  - Returns `count` distinct canonicals (the `canonical` field) sampled without replacement from `master_list`.
  - Caller can then call `display_variants` per canonical to render the actual display form.

- [x] Update `pick_random_words(count)` to delegate to `pick_random_canonicals` and return canonicals as strings. This preserves the caller contract for `_roll_toilet_intel` until task-03 rewrites it — the strings on the toilet strip will temporarily be canonicals (no obfuscation) until task-03 lands, which is fine for incremental verification.

- [x] Update `_refill_queue()` to push canonicals (`entry["canonical"]` for each entry) into `active_queue`. `get_next_batch` continues to return canonicals. Add a comment noting this is vestigial and may be removed in a later phase.

- [x] Add a minimal smoke-test script `potty-secret/.tasks/phase-7/_smoke_canonical.gd` (or inline at the bottom of `WordManager.gd` under an `if OS.is_debug_build()` check — implementer's call). The script must:
  - Call `WordManager.canonicalize("ALIENS")` and assert it returns `"aliens"` (or whatever the canonical case is).
  - Call `WordManager.canonicalize("allens")` and assert it returns the same canonical.
  - Call `WordManager.canonicalize("them")` and assert it returns the same canonical.
  - Call `WordManager.canonicalize("not-a-word")` and assert it returns `""`.
  - Call `WordManager.display_variants("aliens", VariantMode.TYPO)` and assert the returned array has length ≥ 1 and does not contain the canonical (unless the canonical's typos array is empty, which it should not be for "aliens").
  - Print "phase-7 canonical smoke test OK" on success, push_error on failure.
  - If implemented as a standalone script, document how to run it (e.g. `godot --script potty-secret/.tasks/phase-7/_smoke_canonical.gd`).

- [x] Game still runs end-to-end. Opening `game2.tscn` and playing through a shift: intel shows canonicals (no obfuscation yet), paper draws planted words from the canonicals, marking still scores correctly. No regression vs. the pre-task behavior except that intel/paper strings are now sourced via the helper instead of raw `master_list` strings.

## Notes

### What was done

Migrated `WordManager.master_list` from `Array[String]` to `Array[Dictionary]` and added the canonical data model helpers.

### Files modified

- `potty-secret/WordManager.gd` — complete rewrite of master_list (28 entries with typos + synonyms each), added `VariantMode` enum, `canonicalize()`, `display_variants()`, `pick_random_canonicals()`, updated `pick_random_words()` to delegate, updated `_refill_queue()` to extract canonicals from dicts. Added `_normalize()` helper inlined from `text_renderer.gd._normalize_word`.
- `potty-secret/game2.gd` — updated `_single_token_master_words()` to iterate `entry["canonical"]` from the new dict shape instead of raw strings.
- `potty-secret/.tasks/phase-7/_smoke_canonical.gd` — new standalone smoke test script (extends SceneTree, runs headless).

### Key decisions

- Canonicals keep original case (e.g. `"Elvis"`, `"MKUltra"`) because `toilet_msg.gd` renders labels as-is and `text_renderer.gd` normalises for matching. Case is preserved in canonical, lowered only in `_normalize()` for lookup.
- `_normalize()` is inlined in `WordManager` rather than referencing `TextRenderer._normalize_word`, avoiding a cross-singleton dependency.
- Typos and synonyms were authored to avoid normalisation collisions with their own canonical (caught and fixed several during implementation: `Area51` == `Area 51`, `UFo's` == `UFOs`, `JFK.` == `JFK`, `Tupac.` == `Tupac`, `MKUltra` duplicate in typos list).
- Synonym collision between `the Grays`/`aliens` (both had "the visitors") was resolved by using "little men" for the Grays.

### Verification evidence

Smoke test run: `14/14 passed`, printed `phase-7 canonical smoke test OK`.
Project loads clean under `--headless --quit --path .` with no parse errors.

### Concerns / follow-up

- The game-end-to-end AC ("no regression") was verified at the code level (no API breaks) and via clean project load, but a human playthrough is recommended before closing the phase. The task note says "game still runs end-to-end" — this should be confirmed with actual gameplay in the playtest task (task-07).
- `_refill_queue` / `get_next_batch` are vestigial per the comment; confirmed no call sites in `game2.gd`. Safe to remove in a later phase cleanup.
- Smoke script exits with exit code 1 on failure but Godot also emits a resource-leak warning on clean exit (benign Godot headless behaviour, not a test failure).
