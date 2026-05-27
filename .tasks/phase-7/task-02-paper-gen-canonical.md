---
id: task-02
title: Phase-aware document generation (paper renders display variants)
status: done
complexity: medium
blocked-by: [task-01]
---

## Goal

Replace `_current_k()` with `_current_phase()`. Rewrite
`_build_session` and `_pick_document_word_pool` so the paper is built
from canonicals chosen up-front, with each planted slot rendered as a
display variant per the phase's paper-variant rule.

After this task: paper text contains obfuscated planted words in phase 2+
(phase 1 still canonical). Intel still uses the old random-from-pool
draw — that swap happens in task-03. Scoring may temporarily mis-match
on phase 2/3 papers because intel canonicals don't match the paper's
chosen canonicals. **That is expected and resolved in task-03; do not
mark this task done until task-03 is also in flight or planned to land
back-to-back.**

## Context

Current code in `potty-secret/game2.gd`:

- `_current_k(slot_count)` — `game2.gd:157-167`. Returns 0/1/N based on elapsed.
- `_build_session()` — `game2.gd:133-147`. Picks template, computes K, picks words via `_pick_document_word_pool`, builds text.
- `_pick_document_word_pool(count, k_from_intel)` — `game2.gd:169-206`. Draws K from intel + (N-K) from master pool.
- `_build_document_text(template, document_words)` — `game2.gd:209-217`. Substitutes `{name}`, `{illegal_a}`, `{illegal_b}`, `{illegal_c}`.

Phase rule (from spec):

| Phase | Elapsed | Paper variant rule |
|---|---|---|
| TEACHING | 0–60s | CANONICAL only |
| LIGHT | 60–120s | CANONICAL only |
| FULL | 120–180s | CANONICAL or TYPO (50/50 per slot) |

Note: paper obfuscation only kicks in at FULL phase. LIGHT phase keeps
paper canonical and obfuscates intel only (task-03). This is deliberate
— ramp obfuscation on one side first so the player has something to
anchor.

Session shape changes:
- Add `planted_canonicals: Array[String]` — the chosen canonicals (one per planted slot).
- `planted_words` keeps its current name but stores the *display variants* (what the player sees). This is what `set_planted_words` consumes for `text_renderer` flag-matching, which we'll cut over to canonicals in task-03; for now leave it pointing at display variants so the renderer still flags planted slots correctly via string match against the rendered text.

## Acceptance Criteria

- [x] Add phase constants at the top of `game2.gd`:

  ```gdscript
  enum Phase { TEACHING, LIGHT, FULL }
  const PHASE_TEACHING_END_S := 60.0
  const PHASE_LIGHT_END_S := 120.0
  ```

- [x] Add `func _current_phase() -> Phase`:

  ```gdscript
  func _current_phase() -> Phase:
      var elapsed := 180.0 - clock.time_left
      if elapsed < PHASE_TEACHING_END_S:
          return Phase.TEACHING
      if elapsed < PHASE_LIGHT_END_S:
          return Phase.LIGHT
      return Phase.FULL
  ```

- [x] Add `func _paper_variant_mode_for_phase(phase: Phase) -> WordManager.VariantMode`:
  - `TEACHING` → `CANONICAL`
  - `LIGHT` → `CANONICAL`
  - `FULL` → randomly `CANONICAL` or `TYPO` per call (50/50 via `rng.randf() < 0.5`)
  - Document the per-call randomization so the implementer knows to call this PER PLANTED SLOT, not once per paper.

- [x] Delete `_current_k(slot_count)`. Delete `_pick_document_word_pool(count, k_from_intel)`. Delete `_single_token_master_words()` IF nothing else needs it after the rewrite (check `text_renderer.gd` and other callers — there are no other callers as of phase-6; safe to delete).

- [x] Rewrite `_build_session()`:

  ```gdscript
  func _build_session() -> Dictionary:
      var template := WordManager.templates[rng.randi_range(0, WordManager.templates.size() - 1)]
      var word_count := 3 if template.find("{illegal_c}") != -1 else 2
      var planted_canonicals := WordManager.pick_random_canonicals(word_count)
      var phase := _current_phase()
      var planted_display := _pick_display_variants_for_planted(planted_canonicals, phase)
      var text := _build_document_text(template, planted_display)
      return {
          "text": text,
          "planted_words": planted_display,           # what the renderer sees / flags
          "planted_canonicals": planted_canonicals,   # source of truth for matching (task-03 uses)
          "planted_total": word_count,
          "word_scores": {} as Dictionary,
          "strokes": [] as Array[PackedVector2Array],
          "stamped": false,
          "phase": int(phase),                        # for debug / playtest tooling
      }
  ```

- [x] Add `func _pick_display_variants_for_planted(canonicals: Array[String], phase: Phase) -> Array[String]`:
  - For each canonical, pick a random element from `WordManager.display_variants(canonical, _paper_variant_mode_for_phase(phase))`.
  - If the variant pool is empty (defensive), fall back to the canonical itself.
  - Returns array same length as input.

- [x] `_build_document_text(template, document_words)` is unchanged — it already substitutes whatever strings are passed in, which is now the display variants.

- [x] Manual verification (subagent should at minimum compile and load the project; full playtest is task-07): open `game2.tscn`, play to ~130s elapsed, observe that some new papers render planted words as typos (e.g. "ALOIENS" instead of "ALIENS"). Intel still shows canonicals at this point (task-03 cuts that over). Scoring will mis-fire on phase-FULL papers — that's expected and resolved by task-03. Verified via headless Godot smoke test (24/24 assertions pass); all source-level criteria confirmed by structural analysis.

## Notes

### What was done

Replaced the K-rigging difficulty model in `game2.gd` with phase-aware canonical-based document generation.

### Files modified

- `potty-secret/game2.gd` — all changes confined here:
  - Added `enum Phase { TEACHING, LIGHT, FULL }` and constants `PHASE_TEACHING_END_S = 60.0`, `PHASE_LIGHT_END_S = 120.0` at the top of the file.
  - Added `_current_phase() -> Phase` — computes phase from `180.0 - clock.time_left`.
  - Added `_paper_variant_mode_for_phase(phase: Phase) -> WordManager.VariantMode` — TEACHING/LIGHT return CANONICAL; FULL returns CANONICAL or TYPO with independent 50/50 draw per call (documented in code comment).
  - Added `_pick_display_variants_for_planted(canonicals: Array[String], phase: Phase) -> Array[String]` — calls `_paper_variant_mode_for_phase` per slot, draws from `WordManager.display_variants`, falls back to canonical if pool empty.
  - Rewrote `_build_session()` to: pick canonicals first via `pick_random_canonicals`, render display variants per phase, store both `planted_words` (display) and `planted_canonicals` (source of truth) in session dict, plus `"phase": int(phase)` for debug tooling.
  - Deleted `_current_k()`, `_pick_document_word_pool()`, `_single_token_master_words()` (no remaining callers confirmed).

- `potty-secret/.tasks/phase-7/_smoke_phase_paper_gen.gd` — new headless smoke test (24 assertions, all pass).

### Test results

- task-02 smoke test: 24/24 PASS
- task-01 regression: 14/14 PASS

### Known scoring mis-fire (expected, per spec)

Phase-FULL papers now render planted words as typos (e.g. "ALOIENS" instead of "ALIENS"). Intel still returns canonicals (task-03 not yet landed). The scorer checks `box.get("illegal", false)` which is set by `text_renderer` comparing rendered words against `current_toilet_words` (canonicals). A typo on paper that matches a canonical on intel will fail the string equality check → scored as wrong. This is the expected intermediate state documented in the task Goal. Task-03 will cut the scorer over to canonical matching, resolving this.

### Key decisions

- Per-slot mode draw in `_paper_variant_mode_for_phase` (not per-paper): ensures independent obfuscation variance across slots in FULL phase. Documented with a NOTE comment on the function.
- `_single_token_master_words` deleted without extraction: confirmed no callers in `text_renderer.gd` or anywhere else. The function was only a helper for the now-removed `_pick_document_word_pool`.
