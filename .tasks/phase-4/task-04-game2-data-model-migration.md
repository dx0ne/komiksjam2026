---
id: task-04
title: Migrate game2.gd + WordManager data model
status: pending
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

- [ ] `WordManager.shift_correct_illegal: int` removed.
- [ ] `WordManager.shift_score: float = 0.0` added.
- [ ] `game2.gd._ready` resets `shift_score = 0.0`.
- [ ] `game2.gd:588` good-ending check becomes `WordManager.good_ending = WordManager.shift_score > 0`.
- [ ] `game2.gd:336` line — leave the old accumulation expression in place but adapt the field name. It will be replaced wholesale in phase 5; for now it should compile (the existing `result["correct_illegal"]` is an int that widens to float).
- [ ] `game2.gd:412` passes `WordManager.shift_score` to `paper.set_shift_score`.
- [ ] `game2.gd` declares `var _paper_index: int = 0`. `_spawn_fresh_paper` increments it after a successful spawn (or at the end, before returning). First call leaves it at 0 then increments to 1.
- [ ] `session["document_words"]` is renamed to `session["planted_words"]` at every read/write site in `game2.gd`.
- [ ] `session["planted_total"]: int` is set in `_build_session` from `word_count` (the existing 2-or-3 template branch).
- [ ] `session["word_scores"]: Dictionary = {}` is initialized in `_build_session` (empty for now — phase 5 fills it).
- [ ] `_load_session` calls `text_renderer.set_planted_words(session["planted_words"])` after `set_document(...)`.
- [ ] Project compiles. `game2.tscn` boots, papers spawn, scoring still works the old way (whole-paper re-eval).

## Notes

This task is the "phase 4 backbone." It looks big but is mostly a rename
sweep plus four small additions. Keep behavior identical — phase 5 will
gut `_evaluate_paper`.

Be careful at `game2.gd:336`:

```gdscript
WordManager.shift_correct_illegal += result["correct_illegal"]
```

becomes

```gdscript
WordManager.shift_score += float(result["correct_illegal"])
```

This is temporary — phase 5 deletes the line.

Watch for `_pick_toilet_words_for_session` which references
`session["document_words"]`. Either rename the read here too (and let
task-05 remove the function entirely), or leave the function untouched and
let task-05 delete it. Either is fine; pick the safer route for keeping the
build green between tasks.
