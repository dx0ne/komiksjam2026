---
id: task-03
title: Phase 3 verification — headless parse + manual smoke checks
status: pending
complexity: low
blocked-by: task-02
---

## Goal

Write `.tasks/phase-3/verification.md` with the exact PowerShell
commands and manual editor steps the user (or future CI) runs to
confirm phase 3 is complete and has not regressed the rest of the
project. Mirror the shape of `.tasks/phase-2/verification.md`.

## Context

### Source for the format

Read `.tasks/phase-2/verification.md` and follow its structure:

1. Godot binary path header
2. Headless parse section (`--check-only` for `game2.gd`, with the
   carry-over note about the WordManager autoload limitation)
3. Full project headless import section (`--quit`)
4. Manual editor smoke checks for `game2.tscn` (F6 walkthrough)
5. Manual regression check for `game.tscn` (F5)
6. Summary
7. Notes for the user

### What needs to be verified for phase 3

#### Headless parse (same pair of commands as phase 2)

- `game2.gd` parses with `--check-only` (will fail with the documented
  WordManager autoload limitation — that's expected).
- Full project `--quit` import exits 0.

The implementing subagent must run both commands locally and record the
exit codes + relevant output in this task's Notes section, same as
phase 2 task-04 did.

#### Manual editor smoke checks — `game2.tscn` (F6)

Carry forward the phase-2 smoke checks (layout, initial document,
toilet handle pull, marker cursor, drawing+submit, new document, SPACE
toggle, M toggle) and ADD the phase-3-specific checks:

- **Submit gating** — Before pressing **Submit Review**, the **New
  Document** button is visibly disabled (greyed out). After pressing
  Submit, **New Document** becomes enabled and **Submit Review**
  becomes disabled.
- **Tally line** — After Submit, the score label includes a line like
  `Papers reviewed: 1 · passed: 0` (or `passed: 1` if the player got
  it right). The tally accumulates across multiple submit cycles.
- **Briefcase guard (current paper not submitted)** — Without
  pressing Submit, click `gimme_toilet_btn2` (the briefcase). Nothing
  should happen visually; the scene should NOT change to ending.tscn.
  (The Output console will show a "briefcase pressed but current
  paper not yet submitted — ignored" line — verify if you have the
  console open.)
- **Briefcase trigger (good ending)** — Press Submit on a paper where
  every illegal word was correctly redacted (APPROVED). Then click the
  briefcase. The scene should change to `ending.tscn` and the **good**
  ending video plays.
- **Briefcase trigger (bad ending)** — Restart `game2.tscn`, press
  Submit on a paper without redacting anything (so it fails). Click
  the briefcase. The scene should change to `ending.tscn` and the
  **bad** ending video plays.
- **Clock timeout (bad ending fallback)** — Restart `game2.tscn`, do
  NOT submit anything, wait for the clock to run down (180 s by
  default — too long for routine smoke testing, so this check is
  optional). Confirm the scene changes to `ending.tscn` and plays the
  bad ending. Document this as `[ ] user-run (optional, slow)`.
- **`skip_to_ending` debug shortcut** — At any time, press the key
  bound to the `skip_to_ending` action (check `project.godot`
  for the binding — typically a single key like `K`). Confirm the
  scene changes to `ending.tscn`. The good/bad video reflects the
  current `paper_results`.

#### Manual regression check — `game.tscn` (F5)

Same as phase 2: open `game.tscn`, press F5, confirm the original
game still runs, ends correctly via clock timeout / briefcase, and
`ending.tscn` still plays. Phase 3 must not regress the legacy flow.

### Files

- Read `.tasks/phase-2/verification.md` as the template.
- Read `.tasks/phase-3/phase.md` for the phase exit criteria.
- Read `potty-secret/project.godot` to find the actual key binding for
  `skip_to_ending`, and include that key in the verification doc so the
  user knows which key to press.
- Write `.tasks/phase-3/verification.md` (new file).

The Godot binary path on this machine is
`D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`.

## Acceptance Criteria

- [ ] `.tasks/phase-3/verification.md` exists.
- [ ] It includes the headless `--check-only` command for `game2.gd`
  with the carry-over WordManager-autoload note.
- [ ] It includes the full-project `--quit` import command.
- [ ] It includes the phase-2 smoke checks (or references them) AND the
  phase-3-specific checks listed above, each as a `[ ] user-run`
  checkbox.
- [ ] The actual key for `skip_to_ending` is read from
  `project.godot` and named in the verification doc.
- [ ] It includes the `game.tscn` regression check.
- [ ] The headless commands have been executed locally by the
  implementing subagent — record exit codes + any output in this
  task's Notes section. Manual editor checks are deferred to the user.

## Notes

(To be filled in by the implementing subagent: exit codes, the
`skip_to_ending` key binding found, and any deviations.)
