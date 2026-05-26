---
id: task-02
title: Drive per-paper UI from word_scores
status: done
complexity: medium
blocked-by: [task-01]
---

## Goal

Switch the post-it `X/Y`, penalty number, stamp eligibility, and stroke
coloring to read `session["word_scores"]` instead of re-deriving via
`_evaluate_paper`. After this task, only the briefcase submit path still
calls `_evaluate_paper` (for the stamp-earned check — replaced in task-03).

## Context

Spec §"Per-paper UI":

- Post-it `X` = count of planted words with `state ∈ {partial, full}`.
- Post-it `Y` = `session["planted_total"]` (fixed at spawn).
- Penalty = count of words with `state == "wrong"`.
- Stamp earned iff `X == Y AND penalty == 0`.

Spec §"Visual feedback" (the parts that land in phase 5 — popups defer to phase 6):

- Stroke color = sum of this stroke's deltas. Sum > 0 → marker color (leave
  current marker color alone). Sum < 0 → existing red `Color(0.75, 0.1, 0.1, 0.9)`.
  Sum == 0 → marker color (no visual indicator of a no-op stroke).

Relevant code in `potty-secret/game2.gd`:

- `_refresh_postit_and_penalty` (line 436) — currently calls `_evaluate_paper`.
- `_color_stroke_by_result` (line 402) — currently uses `_evaluate_paper` for the
  penalty side-channel and a `lookup` of toilet words.
- `_on_stroke_finished` (line 391) — orchestrates the stroke flow; after task-01
  it already calls `_score_stroke_incremental` and captures its return dict.
- `paper.set_postit(marked, total)`, `paper.set_penalty(amount)`, `paper.set_stamp_visible(bool)`,
  `paper.set_shift_score(score)` — call sites stay the same; only the values change.

`text_renderer.word_boxes[i]["planted"]` is the source of truth for whether a
word is planted (phase-4 task-03).

## Acceptance Criteria

- [x] `_refresh_postit_and_penalty` no longer calls `_evaluate_paper`. Instead it:
  - Iterates `word_boxes` and tallies via `session["word_scores"]`:
    - `marked_planted` += 1 for each planted word whose entry has `state ∈ {"partial", "full"}`.
    - `wrongs` += 1 for each word whose entry has `state == "wrong"`.
  - Calls `active_paper.set_postit(marked_planted, session["planted_total"])`.
  - Calls `active_paper.set_penalty(wrongs)`.
  - Calls `active_paper.set_shift_score(WordManager.shift_score)`.
- [x] `_color_stroke_by_result` is renamed/rewritten as `_color_stroke_by_deltas(stroke_index: int, score_result: Dictionary) -> void` (or equivalent — name it sensibly). Behavior:
  - If `score_result["sum"] < 0.0`: set `marker_layer.stroke_colors[stroke_index] = Color(0.75, 0.1, 0.1, 0.9)`.
  - Else leave the default marker color (already appended by `marker_layer` on stroke completion).
  - Call `marker_layer.queue_redraw()`.
  - No call to `_evaluate_paper`. No `_toilet_lookup` usage.
- [x] `_on_stroke_finished` calls the new color helper with the `_score_stroke_incremental` return value, then `_refresh_postit_and_penalty`.
- [x] The stamp visibility no longer auto-shows mid-stroke — it is only set in `_send_to_briefing` based on the X==Y && penalty==0 check (still using `_evaluate_paper` at this point — that's task-03's job to swap).
- [ ] Project compiles. Manual smoke test scenarios (deferred to human runtime smoke test — no Godot runner available):
  - Mark a planted-and-on-intel word fully → post-it goes from `0/2` (or `0/3`) to `1/N`, shift_score shows the +2.
  - Mark a planted-and-on-intel word partially → post-it goes to `1/N`, shift_score shows +1. Extending the stroke to full coverage → post-it stays `1/N` (still counted once), shift_score shows additional +1 (total +2).
  - Mark a non-intel or non-planted word → post-it unchanged, penalty number increments, shift_score shows -0.5, stroke colored red.
  - Reroll → post-it and penalty unchanged; on-intel highlights shift; word_scores unchanged.

## Notes

### What was done

Replaced the `_evaluate_paper`-based mid-stroke UI path in `potty-secret/game2.gd` with one that reads directly from `session["word_scores"]`.

### Files modified

- `potty-secret/game2.gd` — three function changes:
  1. `_on_stroke_finished`: removed the `_evaluate_paper` call; now passes `stroke_index` and the `_score_stroke_incremental` return dict to `_color_stroke_by_deltas`, then calls `_refresh_postit_and_penalty`. The incoming `stroke` parameter was renamed `_stroke` (unused).
  2. `_color_stroke_by_result` → deleted and replaced by `_color_stroke_by_deltas(stroke_index: int, score_result: Dictionary) -> void`. New implementation: if `score_result["sum"] < 0.0` set the red color at `stroke_index`; else leave default; always call `queue_redraw()`. No `_evaluate_paper`, no `_toilet_lookup`.
  3. `_refresh_postit_and_penalty`: now iterates `text_renderer.word_boxes`, reads `session["word_scores"]` per index, tallies `marked_planted` (planted words with state `partial` or `full`) and `wrongs` (any word with state `wrong`), then calls `set_postit`, `set_penalty`, `set_shift_score`. No `_evaluate_paper` call.

### Key decisions

- `_evaluate_paper` is intentionally left wired in `_send_to_briefing` — that is task-03's scope.
- `set_stamp_visible` is called only in `_load_session` (restoring saved stamp state) and `_send_to_briefing` (awarding stamp at submit) — never in the mid-stroke path.
- The `wrongs` tally counts all words (planted and non-planted) with state `"wrong"`, matching the spec: penalty = count of words with state == wrong.
- Used `.get("sum", 0.0)` in `_color_stroke_by_deltas` as a safe fallback if the score_result dict is missing the key (defensive against future callers).

### Deferred for human runtime smoke test

The "Project compiles + manual smoke test scenarios" AC item requires running Godot. All four smoke-test scenarios are noted in the task AC and should be verified by a human before closing phase-5.

### Concerns / follow-up

None. The change is a direct cut-over with no logic divergence from the spec.
