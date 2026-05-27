---
id: task-03
title: Intel derived from paper canonicals + canonical-based matching
status: in-progress
complexity: medium
blocked-by: [task-02]
---

## Goal

Cut intel generation over to the new model: intel is rolled from the
current paper's `planted_canonicals` (always covers them at the
canonical level), with each intel word rendered as a display variant
chosen by the phase rule. Also rewire `text_renderer.gd` and matching
so "illegal" is computed via canonical equivalence, not by string
membership in `current_toilet_words`.

After this task: phases 1, 2, and 3 should all work as designed.
Marking a paper word `W` scores iff `canonicalize(W)` is in the current
paper's planted canonical set. Pull-spam still exists (it rerolls intel
display variants only — paper unchanged). Task-05 fixes the pull
semantics.

## Context

Current intel flow:

- `WordManager.current_toilet_words: Array[String]` — `WordManager.gd:5`. Strings shown on intel and used by `text_renderer.set_forbidden_words` for `illegal` flag.
- `_roll_toilet_intel(animate_msgs)` — `game2.gd:299-332`. Picks random words via `WordManager.pick_random_words`, instantiates `toilet_msg` nodes, animates in.
- `_apply_toilet_to_current_paper()` — `game2.gd:334-340`. Calls `text_renderer.set_forbidden_words(current_toilet_words)` then re-applies strokes (which re-fires coverage but NOT scoring — invariant from phase 5).
- `text_renderer.set_forbidden_words(words)` — `text_renderer.gd:37-48`. Builds a normalized lookup and sets `illegal` per box by string match.
- `text_renderer._relayout()` — `text_renderer.gd:81-123`. Also computes `illegal` per box via lookup.

The change: `illegal` becomes "canonical of this word is in the current intel canonical set", not "this word string is in `current_toilet_words`".

Phase rule for intel:

| Phase | Intel variant rule |
|---|---|
| TEACHING | CANONICAL only |
| LIGHT | TYPO or SYNONYM (50/50 per slot) |
| FULL | TYPO + SYNONYM mixed (TYPO_OR_SYNONYM mode, per-slot random) |

## Acceptance Criteria

- [ ] Add `var current_toilet_canonicals: Array[String] = []` to `WordManager.gd` (alongside `current_toilet_words`). This is the source of truth for matching; `current_toilet_words` becomes the display-only mirror.

- [ ] Add `func _intel_variant_mode_for_phase(phase: Phase) -> WordManager.VariantMode` in `game2.gd`:
  - `TEACHING` → `CANONICAL`
  - `LIGHT` → `TYPO` or `SYNONYM` per slot (50/50)
  - `FULL` → `TYPO_OR_SYNONYM` per slot

- [ ] Rewrite `_roll_toilet_intel(animate_msgs: bool)` to take its source from the *current paper's* planted canonicals:

  ```gdscript
  func _roll_toilet_intel(animate_msgs: bool = true) -> void:
      for child in %toilet_msgs_container.get_children():
          child.queue_free()

      var canonicals: Array[String] = []
      if not session.is_empty() and session.has("planted_canonicals"):
          canonicals = session["planted_canonicals"]
      if canonicals.is_empty():
          # No paper yet — clear intel state and return. (After this task, _roll_toilet_intel
          # is always called AFTER _spawn_fresh_paper, so this guard mainly protects against
          # accidental ordering regressions.)
          WordManager.current_toilet_canonicals = []
          WordManager.current_toilet_words = []
          return

      var phase := _current_phase()
      var display_words: Array[String] = []
      for c in canonicals:
          var mode := _intel_variant_mode_for_phase(phase)
          var pool := WordManager.display_variants(c, mode)
          if pool.is_empty():
              pool = [c]
          display_words.append(pool[rng.randi_range(0, pool.size() - 1)])

      WordManager.current_toilet_canonicals = canonicals.duplicate()
      WordManager.current_toilet_words = display_words

      # ...existing animation block, iterating over display_words instead of current_toilet_words slice...
      if not animate_msgs:
          if session.has("text"):
              _apply_toilet_to_current_paper()
          return
      # (keep the existing tween + y_padding loop, but read from display_words.size() and display_words[i])
      # ...
      if session.has("text"):
          _apply_toilet_to_current_paper()
  ```

  Preserve the existing animation logic (lines 309-328) by iterating over `display_words` instead of `WordManager.current_toilet_words` slice. The number of intel labels shown is now `canonicals.size()` (i.e. equal to the paper's planted_total), not the old `TOILET_INTEL_COUNT = 3`. Update or remove `TOILET_INTEL_COUNT` accordingly — leave the const in place but note it's only used as a fallback / default in legacy code paths.

- [ ] In `_ready()` (`game2.gd:44-56`), remove the `_roll_toilet_intel(true)` call BEFORE `_spawn_fresh_paper(false)`. Replace the order:

  ```gdscript
  WordManager.shift_score = 0.0
  _spawn_fresh_paper(false)   # builds session, including planted_canonicals
  _roll_toilet_intel(true)    # now consumes session.planted_canonicals
  ```

  Note: `_spawn_fresh_paper(false)` calls `_load_session()` which calls `text_renderer.set_document(text, WordManager.current_toilet_words)`. On the very first paper, `current_toilet_words` is empty, so all `illegal` flags will be false until `_roll_toilet_intel` fires and `_apply_toilet_to_current_paper` re-applies them. That's fine — confirm visually that the first paper's flags settle correctly once intel animates in.

- [ ] Replace string-based `illegal` computation in `text_renderer.gd` with canonical-based:

  - `set_forbidden_words(forbidden_words)` (`text_renderer.gd:37-48`): change body to iterate `word_boxes` and set `box["illegal"] = WordManager.canonicalize(box["word"]) in WordManager.current_toilet_canonicals`. The `forbidden_words` parameter is kept for API stability (callers still pass `current_toilet_words` for legacy reasons) but is no longer the source of truth.

  - `_relayout()` (`text_renderer.gd:81-123`): replace the `forbidden_lookup` block with `box["illegal"] = WordManager.canonicalize(canonical_word) in WordManager.current_toilet_canonicals`. Same for the planted check, but `planted` should now also use canonical matching: `box["planted"] = WordManager.canonicalize(canonical_word) in _planted_canonicals_set()`. Add a small helper to convert `planted_words` (display strings) into their canonicals for the lookup, OR change `set_planted_words` to accept `planted_canonicals: Array[String]` directly (see next bullet).

  - `set_planted_words(words)` (`text_renderer.gd:51-58`): rename to `set_planted_canonicals(canonicals)` and store as `planted_canonicals: Array[String]`. Update the body to set `box["planted"] = WordManager.canonicalize(box["word"]) in canonicals`. Update `_relayout` to use the same set. Remove the legacy `planted_words: Array[String]` field if nothing else reads it.

- [ ] Update `game2.gd._load_session()` (`game2.gd:220-234`) to call `text_renderer.set_planted_canonicals(session["planted_canonicals"])` instead of `set_planted_words(session["planted_words"])`. The `planted_words` (display variants) field on session is retained for debug / stamp logic, but the renderer's planted-flag source of truth is now canonicals.

- [ ] Smoke-test in the editor: with two planted slots, render the paper at PHASE_FULL elapsed time. Verify that intel shows obfuscated display variants (e.g. "ALOIENS" + "EVLIS") and marking the original canonical words on the paper still scores `+2`. Mark a non-target word, confirm `-0.5`.

- [ ] Pull lever still works as a pure intel reroll (not yet the advance action — task-05 fixes that). Pulling should reroll intel display variants for the same paper's canonicals (so the *same words* on intel appear in different obfuscated forms each pull). This is acceptable transitional behavior; the player will likely notice that intel words "change" while the paper doesn't — call this out in the task-07 playtest if it manifests in playtesting.

## Notes

_Filled in after task completion._
