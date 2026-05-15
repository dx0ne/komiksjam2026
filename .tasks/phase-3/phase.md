---
phase: 3
title: Scoring & verdict wiring
status: open
opened: 2026-05-15
closed: ~
---

## Goal

Restore real scoring on top of `game2.tscn`: per-paper score, multi-paper
session score, and the win/lose decision that drives the existing
`ending.tscn` transition.

In phase 2, `_on_submit_pressed` shows a per-document verdict label but
nothing accumulates across documents and `_on_time_out` /
`gimme_toilet_btn2` are stubs. This phase wires those up so game2 has the
same end-of-shift behaviour as the original `game.tscn`: at clock timeout
or briefcase trigger, every paper's pass/fail is rolled up into
`WordManager.good_ending` and the scene changes to `ending.tscn`.

## Exit Criteria

- After **Submit Review**, the per-paper verdict (pass / fail) is recorded
  in a session list. The on-screen score label shows both the current
  paper's verdict and a running tally (e.g. `Papers reviewed: 2/3 ·
  passed: 1`).
- **New Document** is gated on the current paper having been submitted
  — the player can no longer regenerate text mid-redaction without
  submitting first.
- The clock's `time_out` signal triggers the verdict path: papers not yet
  submitted count as fails; if every submitted paper passed and at least
  one paper was submitted, `WordManager.good_ending = true`, otherwise
  `false`. Scene changes to `res://ending.tscn`.
- The briefcase trigger (`gimme_toilet_btn2`) calls the same verdict path
  but only when the current paper has been submitted (mirroring the
  original `try_end_game()` "all filled" guard).
- A debug action (`skip_to_ending`, already in `project.godot`) also
  triggers the verdict path, matching the original game's developer
  shortcut.
- `ending.tscn` plays the good/bad ending video correctly based on
  `WordManager.good_ending` (already implemented in `ending.gd`; this
  phase just needs to confirm the value is set before the scene change).
- `game.tscn` (the original main scene) still works — phase 3 must not
  regress the legacy flow.

## Tasks

- [ ] task-01-per-paper-score-tracking.md
- [ ] task-02-verdict-and-ending-transition.md
- [ ] task-03-verification.md
