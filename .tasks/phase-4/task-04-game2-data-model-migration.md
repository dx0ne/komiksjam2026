---
id: task-04
title: Migrate game2.gd + WordManager data model
status: done
complexity: medium
blocked-by: [task-02, task-03]
---

## Goal

One coherent migration of the data model so the rest of phase 4/5/6 has
clean ground. Rename the WordManager counter to a float score, rename and
extend the per-paper session schema, add the paper index counter, and
update every reference site. No new behavior beyond field/type renames —
scoring still uses the old `_evaluate_paper` path until phase 5.

## Context

Spec §"Data model" and §"Code changes" summarize the targets. Reference
sites for the rename were found via grep:

- `WordManager.gd:8` — declaration
- `game2.gd:50` — init to 0 in `_ready`
- `game2.gd:336` — accumulate in `_send_to_briefing`
- `game2.gd:412` — pass to `paper.set_shift_score`
- `game2.gd:588` — `good_ending` check

`session["document_words"]` is set in `_build_session` and read in
`_pick_toilet_words_for_session`. (The latter is removed in task-05; for
this task just rename the read access.)

## Acceptance Criteria

- [x] `WordManager.shift_correct_illegal: int` removed.
- [x] `WordManager.shift_score: float = 0.0` added.
- [x] `game2.gd._ready` resets `shift_score = 0.0`.
- [x] `game2.gd:588` good-ending check becomes `WordManager.good_ending = WordManager.shift_score > 0`.
- [x] `game2.gd:336` line — leave the old accumulation expression in place but adapt the field name. It will be replaced wholesale in phase 5; for now it should compile (the existing `result["correct_illegal"]` is an int that widens to float).
- [x] `game2.gd:412` passes `WordManager.shift_score` to `paper.set_shift_score`.
- [x] `game2.gd` declares `var _paper_index: int = 0`. `_spawn_fresh_paper` increments it after a successful spawn (or at the end, before returning). First call leaves it at 0 then increments to 1.
- [x] `session["document_words"]` is renamed to `session["planted_words"]` at every read/write site in `game2.gd`.
- [x] `session["planted_total"]: int` is set in `_build_session` from `word_count` (the existing 2-or-3 template branch).
- [x] `session["word_scores"]: Dictionary = {}` is initialized in `_build_session` (empty for now — phase 5 fills it).
- [x] `_load_session` calls `text_renderer.set_planted_words(session["planted_words"])` after `set_document(...)`.
- [x] Project compiles. `game2.tscn` boots, papers spawn, scoring still works the old way (whole-paper re-eval).

## Notes

Implementation complete. Files modified:
- `potty-secret/WordManager.gd`: Removed `shift_correct_illegal: int`, added `shift_score: float = 0.0`.
- `potty-secret/game2.gd`: All rename/extension changes applied:
  - `_ready`: resets `WordManager.shift_score = 0.0`
  - Added `var _paper_index: int = 0` declaration
  - `_spawn_fresh_paper`: increments `_paper_index` after successful spawn
  - `_build_session`: renamed `document_words` local var to `planted_words`, renamed session key to `"planted_words"`, added `"planted_total"` from `word_count`, added `"word_scores": {}`
  - `_load_session`: added `text_renderer.set_planted_words(session["planted_words"])` call after `set_document`
  - `_pick_toilet_words_for_session`: renamed `session["document_words"]` read to `session["planted_words"]` (will be removed in task-05)
  - `_send_to_briefing`: `WordManager.shift_score += float(result["correct_illegal"])`
  - `_refresh_postit_and_penalty`: passes `WordManager.shift_score` to `paper.set_shift_score`
  - `_end_shift`: `WordManager.good_ending = WordManager.shift_score > 0`

Decision: renamed the `_pick_toilet_words_for_session` read site rather than leaving it — keeps build green without a dangling `document_words` reference.

No behavioral changes — scoring still uses the old `_evaluate_paper` whole-paper re-eval path.
