---
id: task-04
title: Manual playtest checklist + verification
status: pending
complexity: low
blocked-by: [task-02]
---

## Goal

Produce a structured playtest checklist that a human can execute by
opening `game2.tscn` in the Godot editor, then run the playtest and
record results. The checklist must cover every exit-criterion scenario
from `phase.md` so we have explicit evidence the phase-4/5/6 work feels
right end-to-end. This is the only place the project actually exercises
the engine for this phase — every prior task has deferred runtime
verification.

## Context

Cannot run Godot headlessly in CI here. The subagent's job is:

1. Produce the checklist (clear, repeatable steps).
2. Attempt to run it. If the environment allows launching Godot, do so
   and walk through; otherwise, file the checklist as a deferred-to-human
   artifact in `phase-6/playtest-results.md` with each item flagged
   "needs human run" and the rationale.
3. If the subagent *can* run Godot and observes a regression, document
   it in Notes — do NOT mark the task done. Either fix it (if small)
   or set status `blocked` so the human can address before phase close.

The checklist must explicitly call out the four critical scenarios from
the phase exit criteria (paper #1 forced random, easy/mixed/random
phases, submit penalty, negative shift score).

## Acceptance Criteria

- [ ] Create `potty-secret/.tasks/phase-6/playtest-results.md` (or
      `.tasks/phase-6/playtest-results.md` — match existing convention
      from prior phases) containing:
  - One section per scenario, with **Steps**, **Expected**, **Observed**, **Pass/Fail**.
  - Scenarios required:
    1. **First paper forced random** — open `game2.tscn`, check that the first paper's planted words are NOT all on intel (verify by counting on-intel highlights vs planted slots; need at least one mismatch for K=0).
    2. **Easy phase (0–60s)** — after pulling toilet once and triggering a new paper before 60s, all planted words on the new paper are on intel.
    3. **Mixed phase (60–120s)** — paper spawned in this window has exactly one planted word on intel; the rest from master pool.
    4. **Random phase (120–180s)** — paper spawned after 120s has zero planted words on intel.
    5. **At-mark scoring** — mark a planted+on-intel word: see `+1` popup if half coverage, `+2` if full. Re-stroke the same full word: no popup, score does not change.
    6. **Wrong mark penalty** — mark a clean word: see `-0.5` popup, stroke turns red, penalty counter increments.
    7. **Submit penalty** — leave a planted word untouched, press briefcase: see `-0.5` popup briefly before paper advances; `shift_score` drops by 0.5 per unmarked planted.
    8. **Negative shift score** — make enough wrong marks to drive `shift_score` below zero; verify post-it shows `-1.5` (or similar) with leading minus, no `+` sign.
    9. **Popup z-order** — popups visibly sit ABOVE the marker ink, not underneath.
- [ ] Each scenario lists the exact in-editor or in-game inputs (drag from X to Y on paper, click briefcase, etc.) — terse but unambiguous.
- [ ] If the subagent ran the playtest, fill **Observed** + **Pass/Fail**. If deferred, write `Observed: <deferred — needs human run>` and `Pass/Fail: ?`.
- [ ] Update `phase.md`'s exit-criteria checklist (the last bullet about manual playtest) to point at the results doc.
- [ ] If any regressions are found, file them in Notes with file/line references and either fix-in-place (small) or set the task status to `blocked` with clear handoff.

## Notes

_Filled in by the subagent during/after implementation._
