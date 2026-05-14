---
id: task-04
title: Phase 2 verification — headless parse + manual smoke checks
status: pending
complexity: low
blocked-by: task-03
---

## Goal

Write `.tasks/phase-2/verification.md` with the exact PowerShell commands
and manual editor steps the user (or future CI) runs to confirm phase 2
is complete and has not regressed the rest of the project. Mirror the
shape of `.tasks/phase-1/verification.md`.

## Context

### Source for the format

Read `.tasks/phase-1/verification.md` and follow its structure:

1. Godot binary path header
2. Headless parse section (per-script `--check-only` commands)
3. Full project headless import section (`--quit`)
4. Manual editor smoke checks (F6 / F5 walkthroughs)
5. Manual regression check
6. Summary
7. Notes for the user

### What needs to be verified for phase 2

#### Headless parse

- `game2.gd` parses with `--check-only`.

  ```powershell
  & "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd
  ```

  Note the known limitation from phase 1: cross-script `class_name`
  references (TextRenderer, MarkerLayer, MarkerCursorLayer, DebugOverlay)
  may report parse errors during single-file `--check-only`; these
  resolve at full project import. Document this carry-over.

#### Full project import

```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit
```

Should exit 0 with no missing-UID / missing-resource warnings.

#### Manual editor smoke checks — game2.tscn

Run via F6 (do NOT repoint `run/main_scene`). Walkthrough:

- **Layout check** — Visible: background (Tlo), frame (Ramka), toilet
  handle on the left edge, clock on the lower-left, ashtray top-right,
  coffee, paperclips on the briefcase, and the paper region with text
  somewhere central. UI panel (Submit / New Document / score /
  directive / title / clock label) is visible and not overlapping the
  decor in an obstructive way.
- **Initial document** — On scene start, paper shows procedurally
  generated text with two illegal words from `WordManager`. Directive
  label lists those two illegal words.
- **Toilet handle pull** — Click `gimme_toilet_btn` once. Three toilet
  paper messages tween into position with three different words. The
  paper text regenerates so the illegal set matches the new toilet
  words. Directive label updates to the new illegal pair.
- **Marker cursor** — Custom thick black marker cursor appears over the
  paper region; OS cursor appears outside.
- **Drawing + submit** — Drag a stroke across an illegal word, press
  **Submit Review**. Tick (green) appears beside it. Stroke over a legal
  word gives a red cross. Missed illegal words blink red. Score label
  shows verdict text (APPROVED / REVIEW FAILED) and counts. **No scene
  change to ending.tscn.**
- **New Document** — Press **New Document**. Strokes clear, paper text
  regenerates (illegal set may stay the same — toilet pull is what
  changes the batch). Marker unlocks; player can draw again.
- **SPACE toggle** — SPACE toggles the debug overlay (word rects,
  tolerance bounds, sample dots after submit).
- **M toggle** — M flips marker mode between LINE and BRUSH; score
  label updates to show the current mode.

#### Manual regression check — game.tscn

Open `game.tscn`, press F5, confirm the original game still runs without
errors. Phase 2 must not have broken anything.

### Files

- Read `.tasks/phase-1/verification.md` as the template.
- Read `.tasks/phase-2/phase.md` for the phase exit criteria.
- Write `.tasks/phase-2/verification.md` (new file).

The Godot binary path on this machine is
`D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`.

## Acceptance Criteria

- [ ] `.tasks/phase-2/verification.md` exists.
- [ ] It includes the exact PowerShell `--check-only` command for
  `game2.gd`.
- [ ] It includes the full-project `--quit` import command.
- [ ] It includes the manual editor smoke checks listed above, each as
  a `[ ] user-run` checkbox so the user can sign off interactively.
- [ ] It includes the `game.tscn` regression check.
- [ ] It documents the known cross-script `class_name` `--check-only`
  limitation carried over from phase 1.
- [ ] The headless commands in the document have been executed locally
  by the subagent and exit 0 — record the output (or any errors) in
  the Notes section of this task file. Manual editor checks are
  deferred to the user.

## Notes

(filled in by implementer)
