---
phase: 5
title: At-mark scoring + submit penalty
status: closed
opened: 2026-05-26
closed: 2026-05-26
---

## Goal

Replace the whole-paper re-evaluation model with locked per-mark scoring.
Implement the spec's transition table (+2 full / +1 partial / -0.5 wrong),
make scores immutable after the stroke that earned them, and apply the
submit-time penalty for unmarked planted words. End state: feature-complete
gameplay; only the visual polish (phase 6) remains.

## Exit Criteria

- `_evaluate_paper`, `_color_stroke_by_result`, and any other whole-paper re-derivation are removed from `game2.gd`.
- New `_score_stroke_incremental(stroke_index)` walks word_boxes, applies the transition table, and writes deltas into `session["word_scores"]` and `WordManager.shift_score`.
- `_on_stroke_finished` triggers the incremental scorer; reroll (`_apply_toilet_to_current_paper`) does NOT touch `word_scores`.
- `_apply_submit_penalty()` runs at briefcase submit: untouched planted words → `wrong` state, -0.5 each.
- Post-it `X/Y`, penalty count, and stamp readout are driven by `word_scores` (not by re-derivation).
- Manual verification: mark a word, reroll, score persists; mark non-intel word, get -0.5 once; submit with unmarked planted, eat penalty.

## Reference

Design spec: `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`
(sections "At-mark scoring", "Submit-time penalty", "Per-paper UI", "Reroll behavior").

## Tasks

- [x] task-01-incremental-scorer.md
- [x] task-02-ui-reads-from-word-scores.md
- [x] task-03-submit-penalty-and-cleanup.md
