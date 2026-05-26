---
id: task-03
title: Submit penalty + remove _evaluate_paper
status: in-progress
complexity: medium
blocked-by: [task-02]
---

## Goal

Implement the briefcase submit-time penalty for unmarked planted words and
fully retire whole-paper re-evaluation. End state: `_evaluate_paper`,
`_color_stroke_by_result`, and any helpers that only existed to serve them
are gone; `_send_to_briefing` drives stamp eligibility entirely from
`session["word_scores"]`.

## Context

Spec §"Submit-time penalty":

- On briefcase submit, for each word with `planted == true AND state == "untouched"` (or no entry), apply -0.5 and set `state = "wrong"`. Update `WordManager.shift_score`.
- This is *not* a re-evaluation — it only scores previously unscored words.
- Stamp earned iff `X == Y AND penalty == 0` measured AFTER the penalty pass.

Relevant code in `potty-secret/game2.gd`:

- `_send_to_briefing` (line 362) — currently calls `_evaluate_paper`, accumulates `correct_illegal` (already removed in task-01), and checks `all_illegal_marked && false_redactions == 0` for the stamp.
- `_evaluate_paper` (line 449) — full re-eval body. After task-02 the only remaining caller is `_send_to_briefing`. Both must go in this task.
- Helpers that may be orphaned once `_evaluate_paper` is gone: `_toilet_lookup` (line 542), the stroke-from-array variant `_stroke_samples_in_text_space_from_array` (line 584) if not used elsewhere. Audit and delete only the ones that have zero remaining callers.

`session["planted_total"]` (set in `_build_session`) is the post-it `Y` — the
authoritative slot count for stamp eligibility.

## Acceptance Criteria

- [ ] New `_apply_submit_penalty() -> int`:
  - Iterates `word_boxes`. For each box with `planted == true` whose `session["word_scores"]` entry is missing or has `state == "untouched"`:
    - Sets `session["word_scores"][i] = {"state": "wrong", "points": -0.5}`.
    - Adds `-0.5` to `WordManager.shift_score`.
    - Increments a local counter.
  - Returns the count of newly-penalized words.
- [ ] `_send_to_briefing` is rewritten:
  - `_save_session()` as today.
  - Call `_apply_submit_penalty()` (return value used for the smoke test / debug if useful, not required for UI).
  - Compute stamp eligibility from `session["word_scores"]`:
    - `marked_planted` = count of planted words with state ∈ {partial, full}.
    - `wrongs` = count of words with state == wrong.
    - `earned_stamp = marked_planted == session["planted_total"] AND wrongs == 0`.
  - If `earned_stamp`: `session["stamped"] = true`; `active_paper.set_stamp_visible(true)`.
  - Call `_refresh_postit_and_penalty()` so the post-it/penalty/shift_score labels reflect the post-penalty state (briefly visible before the new paper animates in).
  - Same advance-paper flow as today (1.25s delay if stamped, else immediate).
  - No call to `_evaluate_paper`.
- [ ] `_evaluate_paper` and `_color_stroke_by_result` (or whatever task-02 renamed it to — keep the new one) are deleted. Any helpers with zero remaining callers (likely `_toilet_lookup`, possibly `_stroke_samples_in_text_space_from_array`) are deleted. Verify by grep before removing — do not delete a helper that still has callers.
- [ ] Project compiles, no parse errors, no unresolved identifiers. `game2.tscn` boots and a full shift can be played start to finish.
- [ ] Manual verification scenarios (each must work):
  1. Mark a planted-and-on-intel word fully, then reroll: shift_score and post-it persist; the marked word's score is not refunded or duplicated.
  2. Mark a non-planted (or planted-but-not-on-intel) word: -0.5 once. Continuing to extend that stroke does not trigger additional -0.5.
  3. Submit a paper with ≥1 unmarked planted word: each unmarked planted contributes -0.5 to shift_score at submit; the penalty number on the post-it bumps up briefly before the next paper animates in.
  4. Submit a fully-marked paper with zero wrongs: stamp appears, 1.25s delay, next paper spawns.

## Notes

_Filled in by the subagent on completion._
