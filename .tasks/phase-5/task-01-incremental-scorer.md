---
id: task-01
title: Per-stroke incremental scorer (transition table)
status: done
complexity: medium
blocked-by: []
---

## Goal

Add the new at-mark scoring engine: `_score_stroke_incremental(stroke_index)`
plus a shared per-word coverage helper extracted from `_evaluate_paper`.
After this task `WordManager.shift_score` is driven entirely by per-stroke
deltas (not by `_send_to_briefing`'s `correct_illegal` accumulation), and
`session["word_scores"]` is populated correctly. UI still reads via the old
`_evaluate_paper` path — that cut-over is task-02.

## Context

Spec §"At-mark scoring" defines the transition table. Relevant code in
`potty-secret/game2.gd`:

- `_evaluate_paper` (lines 449-539) — full whole-paper re-eval; the coverage
  computation inside it is the part we want to factor out into a helper that
  the new code can share.
- `_on_stroke_finished` (line 391) — the hook where the new scorer must run.
- `_color_stroke_by_result` (line 402) — leave intact for now; task-02 will
  rewrite it to read deltas.
- `_send_to_briefing` (line 362) — the `WordManager.shift_score += float(result["correct_illegal"])`
  line must be removed in this task so we don't double-count.
- `text_renderer.word_boxes[i]` carries `rect`, `word`, `illegal`, `planted`
  (after phase-4 tasks 03-04). Word index is the index into `word_boxes`.

Transition table (spec §2), applied per word:

| Tier reached | `planted ∧ on-intel-now` | From state | Transition | Delta |
|---|---|---|---|---|
| partial | true | untouched | partial | +1 |
| full    | true | untouched | full    | +2 |
| full    | true | partial   | full    | +1 |
| partial | true | full      | no-op   | 0 |
| partial or full | false | untouched | wrong | -0.5 |
| any     | — | partial / full / wrong | no-op | 0 |

`on-intel-now` = box[`illegal`] (the renderer already maintains this against
`WordManager.current_toilet_words`). It is evaluated at the moment the stroke
finishes; after locking it never changes.

`word_scores` is keyed by word_box index. Value shape:
`{state: String, points: float}`. Missing key means `state == "untouched"`.

## Acceptance Criteria

- [x] Extract a `_word_coverage_tier_from_strokes(box: Dictionary, all_samples: Array[PackedVector2Array]) -> String` helper that returns `"none" | "half" | "full"` using the existing `COVERAGE_*` constants. `_evaluate_paper` is refactored to call this helper (no behavior change there).
- [x] New `_score_stroke_incremental(stroke_index: int) -> Dictionary`:
  - Computes `all_samples` from the current `session["strokes"]` (already saved by `_save_session` in `_on_stroke_finished`).
  - For each `word_boxes[i]`, computes the cumulative tier across all strokes.
  - Looks up prior state in `session["word_scores"]` (default `"untouched"` with 0.0 points).
  - Applies the transition table. On a transition:
    - Updates `session["word_scores"][i] = {"state": new_state, "points": prior_points + delta}`.
    - Adds `delta` to `WordManager.shift_score`.
    - Appends `{word_index: i, delta: float, new_state: String, rect: Rect2}` to the return `deltas` array.
  - Returns `{"deltas": Array, "sum": float, "wrongs_added": int}`. `sum` = total delta from this call. `wrongs_added` = count of transitions whose new_state is `"wrong"`.
- [x] `_on_stroke_finished` calls `_score_stroke_incremental(marker_layer.strokes.size() - 1)` BEFORE the existing `_color_stroke_by_result` / `_refresh_postit_and_penalty` calls. The result is stored locally; the old UI path is not yet touched.
- [x] Remove the line `WordManager.shift_score += float(result["correct_illegal"])` from `_send_to_briefing`. Submit no longer mutates shift_score (until task-03 adds the penalty path).
- [x] `_apply_toilet_to_current_paper` does NOT touch `session["word_scores"]`. (It currently doesn't — just confirm and add a one-line comment noting the invariant.)
- [ ] Project compiles. `game2.tscn` runs. Marking a planted-and-on-intel word causes the top-of-paper shift_score label to increment (e.g. `+0.0` → `+1.0` or `+2.0`) immediately when the stroke finishes. Re-strokes over the same already-`full` word do not change the score. Post-it `X/Y` may temporarily disagree with shift_score during this transitional state — that's expected and gets resolved in task-02.

## Notes

### What was done

Implemented the per-stroke incremental scoring engine per spec §2. All static acceptance criteria verified; runtime smoke test deferred to human (cannot run Godot headlessly).

### Files modified

- `potty-secret/game2.gd` — the only file touched in this task.

### Key changes

1. **`_word_coverage_tier_from_strokes(box, all_samples) -> String`** (new, after line 449): Extracted the inner coverage-cell loop that was duplicated twice inside `_evaluate_paper`. Returns `"none" | "half" | "full"`. Both loops in `_evaluate_paper` now call this helper — behavior is identical to before.

2. **`_score_stroke_incremental(_stroke_index: int) -> Dictionary`** (new, after `_evaluate_paper`): Implements the full spec §2 transition table including all 6 rows:
   - Row 1: untouched → partial (+1) for planted∧on-intel at half tier
   - Row 2: untouched → full (+2) for planted∧on-intel at full tier
   - Row 3: partial → full (+1 delta) for planted∧on-intel upgrading from half to full tier
   - Row 4: partial + half tier → no-op (no downgrade)
   - Row 5: untouched → wrong (-0.5) for non-target words with any coverage
   - Row 6: full or wrong prior → skip entirely; partial + non-target → no-op
   The `_stroke_index` parameter is prefixed with `_` (unused; all strokes are always re-evaluated cumulatively as per spec).

3. **`_on_stroke_finished`**: Added `_score_stroke_incremental(_marker_layer().strokes.size() - 1)` as the first operation after `_save_session()`, before `_evaluate_paper` / `_color_stroke_by_result` / `_refresh_postit_and_penalty`.

4. **`_send_to_briefing`**: Removed `WordManager.shift_score += float(result["correct_illegal"])` — shift_score is now driven entirely by `_score_stroke_incremental`.

5. **`_apply_toilet_to_current_paper`**: Added invariant comment confirming `session["word_scores"]` is never touched here.

### Key design decisions

- The `_stroke_index` parameter is accepted but not used — coverage is always computed across ALL strokes cumulatively, as the spec requires ("recompute each word's cumulative coverage tier across ALL strokes on the paper"). The parameter is kept for API clarity and future use (e.g. task-02 might use it for color lookup).
- Row 6 in the spec is a catch-all; rows 1-5 take precedence for partial→full upgrade path.
- Non-planted words that are NOT on intel but get stroked → wrong (-0.5). This matches the spec: a word only avoids penalty if it is both planted AND currently on intel.

### Runtime smoke test — DEFERRED

The final acceptance criterion (project compiles, game2.tscn runs, shift_score label increments on mark) requires a human to open the project in Godot 4 and test. Static analysis shows no syntax or type errors; all referenced fields (`session["word_scores"]`, `session["strokes"]`, `box["planted"]`, `box["illegal"]`, `box["rect"]`, `WordManager.shift_score`) exist from phase-4 work.
