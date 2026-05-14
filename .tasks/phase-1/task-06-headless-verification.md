---
id: task-06
title: Headless parse & smoke-test instructions
status: done
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

- [x] `.tasks/phase-1/verification.md` exists with the exact PowerShell
  commands and the manual checklist.
- [x] All four headless / editor checks pass on the user's machine — user
  ran all manual smoke + regression checks on 2026-05-14, everything worked.

## Notes

### What was done

Created `.tasks/phase-1/verification.md` with the complete Phase 1 verification workflow:

1. **Headless parse checks** — Six PowerShell commands, one for each new script:
   - `text_renderer.gd`
   - `marker_layer.gd`
   - `marker_cursor_layer.gd`
   - `marker_cursor_settings.gd`
   - `debug_overlay.gd`
   - `redaction_test.gd`
   Each uses `godot --headless --path potty-secret --check-only --script scripts/<name>.gd` with the documented Godot binary path.

2. **Full project headless import** — Single PowerShell command:
   `godot --headless --path potty-secret --quit` confirms the entire project imports cleanly with no missing-UID or missing-resource warnings.

3. **Manual editor smoke checks for redaction_test.tscn** — Seven interactive checks (F6, then walk through):
   - Layout (background, paper, UI panels)
   - Text layout (procedural words, directive labels)
   - Marker cursor visibility (custom cursor over paper, OS cursor outside)
   - Drawing and submit (green tick for illegal words, red cross for legal words)
   - Debug overlay toggle (SPACE shows word rects, tolerance bounds, sample dots)
   - Marker mode toggle (M cycles between LINE and BRUSH, score updates)
   - All checks marked as "[ ] user-run" since Claude cannot execute editor UI actions

4. **Manual regression check** — Open `game.tscn`, press F5, confirm original game flow still works without errors.

### Key documentation notes

- Documented the expected limitation: scripts with cross-script `class_name` references (marker_cursor_layer, debug_overlay) may report parse errors during single-file `--check-only`, but these resolve at full project load. Users are explicitly told not to chase these as bugs.
- All PowerShell commands use the exact Godot binary path specified in the brief: `D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`
- Manual checks mirror the deferred acceptance criteria from task-05 (F6, marker cursor, draw/submit, SPACE, M).
- Regression check explicitly includes opening game.tscn to confirm Phase 1 did not break the existing flow.

### Files created

- `.tasks/phase-1/verification.md` — complete verification checklist and commands

### Completion notes

The first acceptance criterion (verification.md exists) is now complete.

The second criterion (all checks pass on the user's machine) **cannot be marked done by Claude** because it requires interactive editor UI testing (F6, drawing, SPACE, M toggles, regression check on F5). The user must run the manual steps in verification.md to confirm that criterion. Once they do, they may mark it complete.

Note: The standalone `--check-only` on scripts like marker_cursor_layer.gd and debug_overlay.gd will likely report parse errors for class_name cross-references. This is documented as an expected limitation in verification.md and does not indicate a real problem — the errors resolve at full project import (step 2).
