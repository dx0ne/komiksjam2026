---
id: task-02
title: Drive per-paper UI from word_scores
status: pending
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

- [ ] `_refresh_postit_and_penalty` no longer calls `_evaluate_paper`. Instead it:
  - Iterates `word_boxes` and tallies via `session["word_scores"]`:
    - `marked_planted` += 1 for each planted word whose entry has `state ∈ {"partial", "full"}`.
    - `wrongs` += 1 for each word whose entry has `state == "wrong"`.
  - Calls `active_paper.set_postit(marked_planted, session["planted_total"])`.
  - Calls `active_paper.set_penalty(wrongs)`.
  - Calls `active_paper.set_shift_score(WordManager.shift_score)`.
- [ ] `_color_stroke_by_result` is renamed/rewritten as `_color_stroke_by_deltas(stroke_index: int, score_result: Dictionary) -> void` (or equivalent — name it sensibly). Behavior:
  - If `score_result["sum"] < 0.0`: set `marker_layer.stroke_colors[stroke_index] = Color(0.75, 0.1, 0.1, 0.9)`.
  - Else leave the default marker color (already appended by `marker_layer` on stroke completion).
  - Call `marker_layer.queue_redraw()`.
  - No call to `_evaluate_paper`. No `_toilet_lookup` usage.
- [ ] `_on_stroke_finished` calls the new color helper with the `_score_stroke_incremental` return value, then `_refresh_postit_and_penalty`.
- [ ] The stamp visibility no longer auto-shows mid-stroke — it is only set in `_send_to_briefing` based on the X==Y && penalty==0 check (still using `_evaluate_paper` at this point — that's task-03's job to swap).
- [ ] Project compiles. Manual smoke test scenarios:
  - Mark a planted-and-on-intel word fully → post-it goes from `0/2` (or `0/3`) to `1/N`, shift_score shows the +2.
  - Mark a planted-and-on-intel word partially → post-it goes to `1/N`, shift_score shows +1. Extending the stroke to full coverage → post-it stays `1/N` (still counted once), shift_score shows additional +1 (total +2).
  - Mark a non-intel or non-planted word → post-it unchanged, penalty number increments, shift_score shows -0.5, stroke colored red.
  - Reroll → post-it and penalty unchanged; on-intel highlights shift; word_scores unchanged.

## Notes

_Filled in by the subagent on completion._
