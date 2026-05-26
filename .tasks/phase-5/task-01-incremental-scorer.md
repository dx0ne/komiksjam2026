---
id: task-01
title: Per-stroke incremental scorer (transition table)
status: in-progress
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

- [ ] Extract a `_word_coverage_tier_from_strokes(box: Dictionary, all_samples: Array[PackedVector2Array]) -> String` helper that returns `"none" | "half" | "full"` using the existing `COVERAGE_*` constants. `_evaluate_paper` is refactored to call this helper (no behavior change there).
- [ ] New `_score_stroke_incremental(stroke_index: int) -> Dictionary`:
  - Computes `all_samples` from the current `session["strokes"]` (already saved by `_save_session` in `_on_stroke_finished`).
  - For each `word_boxes[i]`, computes the cumulative tier across all strokes.
  - Looks up prior state in `session["word_scores"]` (default `"untouched"` with 0.0 points).
  - Applies the transition table. On a transition:
    - Updates `session["word_scores"][i] = {"state": new_state, "points": prior_points + delta}`.
    - Adds `delta` to `WordManager.shift_score`.
    - Appends `{word_index: i, delta: float, new_state: String, rect: Rect2}` to the return `deltas` array.
  - Returns `{"deltas": Array, "sum": float, "wrongs_added": int}`. `sum` = total delta from this call. `wrongs_added` = count of transitions whose new_state is `"wrong"`.
- [ ] `_on_stroke_finished` calls `_score_stroke_incremental(marker_layer.strokes.size() - 1)` BEFORE the existing `_color_stroke_by_result` / `_refresh_postit_and_penalty` calls. The result is stored locally; the old UI path is not yet touched.
- [ ] Remove the line `WordManager.shift_score += float(result["correct_illegal"])` from `_send_to_briefing`. Submit no longer mutates shift_score (until task-03 adds the penalty path).
- [ ] `_apply_toilet_to_current_paper` does NOT touch `session["word_scores"]`. (It currently doesn't — just confirm and add a one-line comment noting the invariant.)
- [ ] Project compiles. `game2.tscn` runs. Marking a planted-and-on-intel word causes the top-of-paper shift_score label to increment (e.g. `+0.0` → `+1.0` or `+2.0`) immediately when the stroke finishes. Re-strokes over the same already-`full` word do not change the score. Post-it `X/Y` may temporarily disagree with shift_score during this transitional state — that's expected and gets resolved in task-02.

## Notes

_Filled in by the subagent on completion._
