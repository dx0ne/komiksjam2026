---
id: task-07
title: Playtest checklist + verification
status: done
complexity: low
blocked-by: [task-06]
---

## Goal

Produce a structured playtest checklist that a human can execute by
opening `game2.tscn` in the Godot editor, then run the playtest and
record results. The checklist must cover every exit-criterion scenario
from `phase.md` so there is explicit evidence the obfuscated-intel
redesign feels right end-to-end.

## Context

Cannot run Godot headlessly in this environment. The subagent's job is:

1. Produce the checklist (clear, repeatable steps) in `.tasks/phase-7/playtest-results.md`.
2. Attempt to run it. If the environment allows launching Godot, walk through; otherwise mark each item "needs human run" and explain in Notes.
3. If the subagent runs Godot and observes a regression, document it in Notes and EITHER fix it (if small) OR mark the task `blocked`.

Match the format/structure of `.tasks/phase-6/playtest-results.md` —
one section per scenario with **Setup**, **Steps**, **Expected**,
**Observed**, **Pass/Fail**, plus a final summary table.

## Acceptance Criteria

- [x] Create `.tasks/phase-7/playtest-results.md` containing scenarios:

  1. **Teaching phase (0–60s): clean win on paper #1.**
     - Setup: launch `game2.tscn`, observe paper #1 + intel strip.
     - Expected: intel shows canonicals only (e.g. "ALIENS", "ELVIS"); paper shows canonicals only; every planted slot's canonical appears verbatim on the intel strip; marking each planted word fully earns `+2`; stamp visible on advance.
     - Pass criterion: no obfuscation, no decoys, marking is straightforward.

  2. **Light phase (60–120s): intel obfuscated, paper canonical, few obvious decoys.**
     - Setup: pull through papers to advance elapsed time past 60s.
     - Expected: intel strip displays typos or synonyms (e.g. "ALOIENS" instead of "ALIENS", or "THEM" instead of "ALIENS"); paper still renders canonicals verbatim; 1–2 decoy words appended in a noise sentence at the end of the paper; the decoys are visibly similar (length, shared letters) to intel words but are NOT canonicals of intel words.
     - Test: read intel, identify the canonical concept, find the matching canonical on the paper, mark it → `+2`. Marking a decoy → `-0.5`, red stroke.

  3. **Full phase (120–180s): paper and intel both obfuscated, close-call decoys.**
     - Setup: continue advancing past 120s.
     - Expected: paper rendering can include typos (e.g. paper shows "ALOIENS" where the planted slot is `aliens`); intel mixes typos and synonyms; 2–4 decoys per paper, visually close to intel display variants (edit distance ≤ 2).
     - Test: even at full obfuscation, every paper is still SOLVABLE. The player must read both sides carefully and match by concept (canonical), not by spelling. Marking a decoy when intel is heavily obfuscated should feel like a real eye-skill failure, not a coin flip.

  4. **Pull lever advances the paper (no -2s clock cost, no submit penalty).**
     - Setup: any active paper with at least one planted word marked.
     - Steps: note current `shift_score`, click toilet handle, observe.
     - Expected: handle bounces, new paper + new intel appear in one transition. `shift_score` is exactly what was earned at mark-time (no -0.5 deductions for unmarked planted slots). Clock is unchanged (within tween jitter — verify by reading the clock value before and after).

  5. **Briefcase is non-interactive.**
     - Setup: any active paper.
     - Steps: click the briefcase sprite (the `Teczka` / `Teczka2` area).
     - Expected: nothing happens. No new paper, no penalty popup, no score change. The cursor may or may not change on hover — that's cosmetic and out of scope.

  6. **Paper spawn originates from the briefcase.**
     - Setup: pull a few times.
     - Expected: each new paper visibly tweens from the briefcase position (between the two `Teczka` sprites) into the working desk position over ~0.35s, with a slight rotation. The first paper of the shift (`animate_in=false`) does NOT animate — it just appears.

  7. **Decoy mismarking penalty + stroke color.**
     - Setup: light or full phase paper with visible decoys in the appended noise sentence.
     - Steps: drag the marker across a decoy word (≥50% coverage).
     - Expected: `-0.5` popup appears at the decoy's position; the stroke renders in RED (not marker color); penalty badge on the post-it increments by 1; `shift_score` drops by 0.5.

  8. **Stamp on perfect redaction (carry-over from phase-6).**
     - Setup: light phase paper, mark every planted slot fully, mark no decoys.
     - Steps: pull the lever.
     - Expected: stamp briefly visible on the paper before it tweens away to make room for the next one.

  9. **Shift end: ending screen reflects at-mark score only.**
     - Setup: any shift in progress.
     - Steps: press debug key `7` (`skip_to_ending`) OR let the clock run out.
     - Expected: ending scene loads. `WordManager.good_ending` is `true` iff `shift_score > 0.0`. No submit-penalty popup is fired during the transition (because there is no submit penalty in the new model).

- [x] Each scenario lists the exact in-editor inputs (drag from X to Y on paper, click briefcase, etc.) — terse but unambiguous.
- [x] **Observed** + **Pass/Fail** filled as `Observed: <deferred — needs human run>` and `Pass/Fail: ?` (Godot not available in environment).
- [x] Update `phase.md`'s exit-criteria list (the playtest bullet) to reference `playtest-results.md`.
- [x] On regressions: no regressions observed (Godot environment unavailable; checklist structured for human execution).

## Notes

### Completion Summary

Playtest checklist created at `.tasks/phase-7/playtest-results.md` with 9 scenarios structured for human execution:

1. **Teaching phase clean win (0–60s)** — canonical-only paper + intel, no obfuscation, no decoys.
2. **Light phase (60–120s)** — paper canonical, intel obfuscated with typos/synonyms, 1–2 obvious decoys.
3. **Full phase (120–180s)** — paper and intel both obfuscated, 2–4 close-call decoys, still solvable.
4. **Pull lever (no clock cost)** — advance action with no -2s penalty, no submit-penalty popup.
5. **Briefcase non-interactive** — click has no effect (scenery only).
6. **Paper spawn animation** — new papers tween from briefcase position over ~0.35s.
7. **Decoy mismarking penalty** — `-0.5` red stroke on marking decoys.
8. **Stamp on perfect redaction** — carry-over from phase 6 (visible after 100% mark, all canonicals, no penalties).
9. **Ending screen at-mark score** — no submit-penalty model; `good_ending` iff `shift_score > 0.0`.

All scenarios include Setup, Steps, Expected columns; Observed/Pass-Fail marked as `_Deferred — needs human run_` / `?` since Godot editor is unavailable in the environment. Phase.md exit-criteria updated to reference the checklist.

**No regressions found** (environment constraint prevents interactive testing; checklist is ready for human execution).
