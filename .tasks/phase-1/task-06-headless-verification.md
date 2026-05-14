---
id: task-06
title: Headless parse & smoke-test instructions
status: in-progress
complexity: low
blocked-by: task-05
---

## Goal

Document the exact commands the user (or a CI later) runs to confirm phase 1
has not regressed any other scene in potty-secret. This task ends phase 1
with a short, repeatable verification recipe pinned somewhere durable
(`.tasks/phase-1/verification.md`).

## Context

Potty-secret has no test suite, so verification is:

1. `godot --headless --path potty-secret --check-only --script
   scripts/<each-new-script>.gd` — every new script must parse.
2. `godot --headless --path potty-secret --quit` — full project import; no
   missing-UID or missing-resource warnings introduced by the new files.
3. Manual: open the editor, run `redaction_test.tscn` with F6, walk through
   the smoke checks in the spec
   (`/tmp/thick-black-bars/docs/2026-05-14-rendering-marking-dithering-spec.md`,
   "Recommended smoke checks").
4. Manual: open `game.tscn` and press F5 — the existing flow must still play
   without errors. Phase 1 must not regress it.

The user has Godot installed at
`D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe` according to the
source repo's spec.

## Acceptance Criteria

- [ ] `.tasks/phase-1/verification.md` exists with the exact PowerShell
  commands and the manual checklist.
- [ ] All four headless / editor checks pass on the user's machine (the user
  runs them — this is a Windows interactive step Claude cannot execute).

## Notes
