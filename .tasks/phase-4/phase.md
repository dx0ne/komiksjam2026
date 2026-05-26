---
phase: 4
title: Foundation & phase-aware document generation
status: closed
opened: 2026-05-26
closed: 2026-05-26
---

## Goal

Land all the data model migrations that the new scoring model needs, plus
flip document generation so planted words come (partially) from current
toilet intel based on shift phase. End state: the game compiles, runs, and
spawns papers with phase-correct planted words — but per-stroke scoring is
still the old whole-paper re-evaluation (phase 5 replaces that).

## Exit Criteria

- Project compiles and `game2.tscn` runs end-to-end without errors.
- `WordManager.shift_correct_illegal` is gone; `WordManager.shift_score: float` is in its place.
- `ShiftClock.time_left` getter exists.
- `text_renderer.word_boxes[i]` has a `planted: bool` key; `set_planted_words()` works.
- `session` carries `planted_words`, `planted_total`, `word_scores` (empty dict ok).
- `_paper_index` increments per spawn; paper #0 overrides to fully random.
- `_pick_toilet_words_for_session()` is deleted; toilet rolls use `WordManager.pick_random_words(3)`.
- `_pick_document_word_pool()` accepts K and merges intel + master pool per phase table in spec.
- Manual smoke test: shift starts, papers spawn, planted-on-intel counts visibly differ between early/mid/late shift.

## Reference

Design spec: `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`
(sections "Phase rules", "Data model", "Code changes").

## Tasks

- [x] task-01-shift-clock-time-left.md
- [x] task-02-paper-shift-score-float.md
- [x] task-03-text-renderer-planted-flag.md
- [x] task-04-game2-data-model-migration.md
- [x] task-05-phase-aware-doc-generation.md
