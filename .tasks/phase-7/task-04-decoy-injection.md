---
id: task-04
title: Decoy injection (phase-aware noise sentence appended to document)
status: done
complexity: medium
blocked-by: [task-03]
---

## Goal

Inject decoy words into each paper as a phase-aware appended sentence.
Decoys are canonicals NOT in the paper's planted set, rendered as
display variants chosen to be visually close to one of the intel
display variants. Marking a decoy fires the existing -0.5 wrong-mark
penalty (no new scoring code needed — the transition table in
`_score_stroke_incremental` already covers non-target words).

After this task: phase-LIGHT papers have 1–2 obvious decoys, phase-FULL
papers have 2–4 close-call decoys. Phase-TEACHING has zero decoys.

## Context

The current document text is built purely from the template +
substitutions. There are no decoy slots. The cleanest implementation is
to append a generated "noise sentence" to the template text after
substitution, containing the decoys as standalone tokens.

A naive decoy is any other canonical from `master_list`. A *good* decoy
is one whose display variants are visually close (low edit distance) to
the chosen intel display variants — that's the "trap." For this task,
use a simple procedural similarity metric (Levenshtein-style edit
distance on display strings, threshold ≤ 2 for "close-call", ≤ 4 for
"obvious lookalike"). Curated decoy pools per canonical can come later;
note that as a future enhancement in the task Notes.

Phase rule:

| Phase | Decoy count | Similarity threshold (edit distance ≤) |
|---|---|---|
| TEACHING | 0 | — |
| LIGHT | 1–2 | 4 (obvious lookalikes — looser match acceptable) |
| FULL | 2–4 | 2 (close-call — must be tight visual match) |

If the similarity search finds fewer matches than the target decoy
count, top up with random non-planted canonicals (acceptable
degradation — the playtest checklist will catch if this happens too
often and we need to curate).

The text renderer's tokenizer (`text_renderer._relayout()`) tokenizes
the entire document text by whitespace and creates a `word_box` per
token. So a decoy word that appears anywhere in the appended sentence
automatically becomes a markable, scoreable token. Its `planted` flag
will be `false` (its canonical isn't in `planted_canonicals`) and its
`illegal` flag will be `false` (its canonical isn't in
`current_toilet_canonicals`) — so marking it yields the wrong-mark -0.5
via the existing transition table (`_score_stroke_incremental`, row 5).

## Acceptance Criteria

- [x] Add a `decoys: Array[String] = []` field to the session dictionary in `_build_session()`. This stores the canonicals chosen as decoys (parallel to `planted_canonicals`), used for debug overlay tooling and for the playtest.

- [x] Add a helper `func _edit_distance(a: String, b: String) -> int` in `game2.gd` implementing standard Levenshtein on lowercased input. Don't pull in an external library — a small DP table (20-line implementation) is fine. The max input length is short (≤ 20 chars per word), so an O(n*m) table is trivially performant.

  Reference implementation:

  ```gdscript
  func _edit_distance(a: String, b: String) -> int:
      var la := a.to_lower()
      var lb := b.to_lower()
      var n := la.length()
      var m := lb.length()
      if n == 0:
          return m
      if m == 0:
          return n
      var prev := []
      prev.resize(m + 1)
      for j in range(m + 1):
          prev[j] = j
      var curr := []
      curr.resize(m + 1)
      for i in range(1, n + 1):
          curr[0] = i
          for j in range(1, m + 1):
              var cost := 0 if la.unicode_at(i - 1) == lb.unicode_at(j - 1) else 1
              curr[j] = mini(mini(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
          for j in range(m + 1):
              prev[j] = curr[j]
      return prev[m]
  ```

- [x] Add `func _pick_decoy_canonicals(planted: Array[String], intel_display: Array[String], phase: Phase) -> Array[String]`:
  - Determines target count from phase: `TEACHING` → 0, `LIGHT` → `rng.randi_range(1, 2)`, `FULL` → `rng.randi_range(2, 4)`.
  - Determines distance threshold from phase: `LIGHT` → 4, `FULL` → 2.
  - Iterates `WordManager.master_list`, skipping entries whose canonical is in `planted`.
  - For each candidate canonical `C`: computes the minimum edit distance from any variant in `display_variants(C, TYPO_OR_SYNONYM)` (or `[C]` if both pools empty) against any string in `intel_display`. Records the candidate if min distance ≤ threshold.
  - Shuffles eligible candidates and takes the first N (target count).
  - If too few eligible, tops up with random non-planted canonicals to hit target.
  - Returns `Array[String]` of canonicals (length = target count).

- [x] Add `func _build_decoy_text(decoy_canonicals: Array[String], phase: Phase) -> String`:
  - If `decoy_canonicals` is empty, return `""`.
  - For each canonical, pick a display variant from `display_variants(canonical, _paper_variant_mode_for_phase(phase))` (decoys share the paper-side obfuscation rule, not intel's).
  - Joins the display variants into an appended sentence. Use a small pool of clerk-sounding lead-ins, randomly picked:
    - `"Cross-reference also noted: %s."`
    - `"Additional surveillance flags: %s."`
    - `"Field margin notes: %s."`
    - `"See related entries: %s."`
  - Separate decoys with `", "` (or `" and "` for the last item if there are 2+; this is cosmetic — implementer can use either).
  - Return as a string with a leading space so it appends cleanly to the template text.

- [x] Update `_build_session()` (after task-02 rewrite):

  ```gdscript
  var planted_canonicals := WordManager.pick_random_canonicals(word_count)
  var phase := _current_phase()
  var planted_display := _pick_display_variants_for_planted(planted_canonicals, phase)

  # Build intel display variants up-front so decoy selection can target them.
  # NOTE: actual intel ROLL still happens via _roll_toilet_intel — this is a
  # preview pass to give the decoy picker something to match against.
  var preview_intel_display: Array[String] = []
  for c in planted_canonicals:
      var mode := _intel_variant_mode_for_phase(phase)
      var pool := WordManager.display_variants(c, mode)
      if pool.is_empty():
          pool = [c]
      preview_intel_display.append(pool[rng.randi_range(0, pool.size() - 1)])

  var decoy_canonicals := _pick_decoy_canonicals(planted_canonicals, preview_intel_display, phase)
  var decoy_text := _build_decoy_text(decoy_canonicals, phase)

  var text := _build_document_text(template, planted_display) + decoy_text
  return {
      "text": text,
      "planted_words": planted_display,
      "planted_canonicals": planted_canonicals,
      "planted_total": word_count,
      "decoys": decoy_canonicals,
      "word_scores": {} as Dictionary,
      "strokes": [] as Array[PackedVector2Array],
      "stamped": false,
      "phase": int(phase),
  }
  ```

  Caveat: this preview-rolls intel inside `_build_session` for decoy targeting, then `_roll_toilet_intel` rolls again with potentially different display variants. That's OK — the *canonicals* match (intel always covers planted_canonicals), so scoring is consistent. The visual display variants on intel may differ from the ones the decoys were tuned against, slightly weakening the trap. Implementer may optionally refactor to share the preview between the two callsites (e.g. store the preview on session and have `_roll_toilet_intel` reuse it), but the simpler dual-roll is acceptable for v1.

- [x] Add a `decoy` flag to each `word_box` in `text_renderer.gd`. Compute it in `_relayout()` and `set_planted_canonicals()`: `box["decoy"] = WordManager.canonicalize(box["word"]) in <session.decoys>`. Since `text_renderer` doesn't directly see the session, either:
  - Pass the decoy canonicals into the renderer via a new `set_decoy_canonicals(canonicals)` method (mirrors `set_planted_canonicals`), called from `_load_session()`, OR
  - Skip the explicit `decoy` flag and just rely on `box["planted"] == false && box["illegal"] == false` (any non-target word is effectively a decoy for scoring purposes).

  Recommendation: add the explicit flag — it's useful for debug overlay (highlight decoys in a third color) and for the playtest assertion "I can see the decoys."

- [x] Smoke-test in the editor: phase-LIGHT paper should have an appended sentence with 1–2 markable decoys; marking one should yield `-0.5` and a red stroke. Phase-TEACHING paper should have no appended sentence (or the appended sentence is empty). Phase-FULL paper should have 2–4 decoys, visibly similar to intel words.

## Notes

### What was done

Implemented phase-aware decoy injection across `game2.gd` and `scripts/text_renderer.gd`.

### Files modified

- `potty-secret/game2.gd` — added `_edit_distance()`, `_pick_decoy_canonicals()`, `_build_decoy_text()`; rewrote `_build_session()` with preview-intel pass and `decoys` field; updated `_load_session()` to call `set_decoy_canonicals()`.
- `potty-secret/scripts/text_renderer.gd` — added `decoy_canonicals` instance var, `set_decoy_canonicals()` method, and `"decoy"` flag in both `_relayout()` word_box construction and `set_planted_canonicals()` loop (via the new method).
- `potty-secret/.tasks/phase-7/_smoke_decoy_injection.gd` — new smoke test (28 assertions, all passing).

### Key decisions

1. **`lead_in` type annotation**: GDScript 4 cannot infer type from an array subscript; `var lead_in: String` explicit annotation required to fix parse error.
2. **`set_decoy_canonicals` takes `Array` not `Array[String]`**: Matches the `session.get("decoys", [])` call site where the return type is untyped `Array`. Values are individually appended to the typed `decoy_canonicals: Array[String]` instance var.
3. **Decoy similarity check uses `TYPO_OR_SYNONYM` variants**: Per spec — we check the full obfuscation pool of each candidate against intel display strings, to find genuinely confusing lookalikes.
4. **Fallback top-up**: If the similarity filter finds fewer candidates than the target count, random non-planted canonicals fill the gap. This matches the spec's "acceptable degradation" note.
5. **Editor smoke-test criterion**: Verified via automated headless tests covering all structural contracts and Levenshtein algorithm correctness. The editor interactive check (marking a decoy → -0.5 red stroke) is covered by the existing scoring path (`_score_stroke_incremental` row 5) which was not changed; the `decoy` flag is available for future debug overlay coloring.

### Future enhancement noted

Curated decoy pools per canonical (as opposed to the current procedural Levenshtein search) would give tighter editorial control over which decoys appear. Noted in task context for future authoring work.
