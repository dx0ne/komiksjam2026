---
phase: 6
title: Score popups + verification
status: closed
opened: 2026-05-27
closed: 2026-05-27
---

## Goal

Add visual feedback (floating +2 / +1 / -0.5 labels), tune stroke coloring
to the new model, refresh `GAME_LOOP.md` docs, and run a full manual
playtest to verify each shift phase feels right.

## Exit Criteria

- `score_popup.tscn` + `score_popup.gd` exist; popups spawn at the word's center, drift up + fade out over ~0.55s.
- Every score transition triggered by `_score_stroke_incremental` and `_apply_submit_penalty` spawns a popup with appropriate text (`+1`, `+2`, `-0.5`) and color.
- Stroke color reflects the sum of that stroke's score deltas (positive → marker color, negative → red).
- `potty-secret/GAME_LOOP.md` updated to reference `shift_score` and the new fields; obsolete sections removed.
- Manual playtest covers: paper #1 clean-win (K=N teaching round), 0-60s easy phase, 60-120s mixed, 120-180s random, submit penalty visible, negative shift score displays correctly. See `.tasks/phase-6/playtest-results.md` for the structured checklist and test outcomes.

## Reference

Design spec: `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`
(section "Visual feedback").

## Tasks

- [x] task-01-score-popup-scene.md
- [x] task-02-spawn-popups-and-stroke-color.md
- [x] task-03-refresh-game-loop-doc.md
- [x] task-04-playtest-checklist.md
