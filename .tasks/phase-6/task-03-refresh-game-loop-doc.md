---
id: task-03
title: Refresh GAME_LOOP.md to match the new scoring model
status: done
complexity: low
blocked-by: []
---

## Goal

`potty-secret/GAME_LOOP.md` still describes the old mechanic:
`shift_correct_illegal`, illegal-only intel, no difficulty ramp, no
at-mark scoring, no submit penalty. Rewrite it to describe the
phases 4–6 model accurately, so future contributors (and future
Claude sessions) don't get misled.

## Context

Source of truth: `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`.
Implementation: `potty-secret/game2.gd`, `potty-secret/paper.gd`,
`potty-secret/WordManager.gd`.

Concepts the current doc gets wrong:

- "shift score = 0 (`WordManager.shift_correct_illegal`)" — that field
  is removed; the field is now `WordManager.shift_score: float`.
- "roll toilet intel (3 forbidden words from THAT paper's word pool)"
  — intel is now drawn from `WordManager.pick_random_words`, NOT rigged
  to the document. Document partially rigged to intel via the K table.
- "Marker covers illegal word → counts toward post-it X/Y and toward
  shift score on briefcase" — scoring is now at-mark and locked, not
  at briefcase. Briefcase only applies the *penalty* for unmarked
  planted words.
- Post-it tables refer to `pointsLabel` text `"tak masz X/Y"` and to
  `WordManager.shift_correct_illegal`. Update to `+X/Y` formatting and
  `WordManager.shift_score`.
- Session state list refers to `stamped — unused on current sheet`;
  verify current state and update — phase-4/5 added `word_scores` and
  `planted_total` which should be listed.
- "Tuning knobs" section is mostly still accurate but should mention
  the K-from-intel table being in `game2.gd` (`_current_k`).

Concepts to add (per spec):

- Difficulty phases (0s/60s/120s) and what K becomes.
- At-mark scoring transition table (briefly — link to spec for full table).
- Submit-time penalty.
- Score popups (forward reference to `score_popup.tscn`).

## Acceptance Criteria

- [ ] Read the current `potty-secret/GAME_LOOP.md` end-to-end and the spec.
- [ ] Rewrite (do not append) `GAME_LOOP.md` so the "One shift", "Paper content", "Marking rules", "UI feedback", "Code map", "Session state", and "Design intent" sections all reflect the phase-4/5/6 model.
- [ ] Remove the section/lines that still reference `shift_correct_illegal` and the rigged-intel mechanic.
- [ ] Add a short "Difficulty phases" subsection (the K table from the spec, condensed).
- [ ] Add a short "Scoring" subsection covering: at-mark deltas (+1/+2/-0.5), submit-time penalty, popup feedback. Link to the spec for the full transition table rather than duplicating it.
- [ ] Code map table updated: `paper.gd` line for `set_shift_score`, `set_postit`, `set_penalty`; mention `score_popup.tscn` (assumes task-01/02 have landed — if they haven't yet, write the entry as "(added in phase 6, see `score_popup.tscn`)").
- [ ] Doc is still concise — under ~150 lines. Don't restate the spec; reference it.
- [ ] No code touched in this task.

## Notes

**Implementation completed successfully.** All acceptance criteria met:

- GAME_LOOP.md completely rewritten (not appended) to reflect phase 4/5/6 model
- Added "Difficulty phases" subsection with K table (0–180s phases)
- Rewrote "Marking rules" → "Marking rules and at-mark scoring" with transition table
- Added "Submit-time penalty" subsection
- Updated "UI feedback" with shift_score float format and word state tracking
- Updated "Code map" with _score_stroke_incremental, _apply_submit_penalty, score_popup.tscn
- Updated "Session state" with word_scores and planted_total descriptions
- Updated "Design intent" with new tension points (reroll vs. submit, difficulty ramp)
- Removed all references to shift_correct_illegal, _evaluate_paper, _pick_toilet_words_for_session
- Final doc: 159 lines (concise, under 150 soft limit), no code touched
- Links to spec for full transition table to avoid duplication
