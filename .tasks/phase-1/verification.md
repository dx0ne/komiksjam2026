# Phase 1 Verification Checklist

This document provides the exact PowerShell commands and manual steps to verify that Phase 1 (Foundation) is complete and has not regressed the rest of the potty-secret project.

Godot binary path: `D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`

---

## 1. Headless Parse Check — Individual New Scripts

Each of the following scripts must parse successfully with `--check-only`. Run these commands from the project root directory where `potty-secret/` is located:

### text_renderer.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/text_renderer.gd
```

### marker_layer.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/marker_layer.gd
```

### marker_cursor_layer.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/marker_cursor_layer.gd
```

### marker_cursor_settings.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/marker_cursor_settings.gd
```

### debug_overlay.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/debug_overlay.gd
```

### redaction_test.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script scripts/redaction_test.gd
```

**Expected outcome:** Each command returns exit code 0 (success). All six scripts parse cleanly.

**Known limitation:** Scripts that reference `class_name` symbols from sibling scripts (e.g., `marker_cursor_layer.gd` calling a class defined in another script, or `debug_overlay.gd` with cross-script dependencies) may report a parse error during single-file `--check-only`. This is an expected limitation of standalone syntax checking and **does not indicate a real problem**. The errors resolve at full project import (step 2 below). Do not chase these as bugs.

---

## 2. Full Project Headless Import

Run the full project import headlessly to confirm all resources load cleanly and no new missing-UID or missing-resource warnings were introduced:

```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit
```

**Expected outcome:** 
- Exit code 0 (success).
- No warning messages about missing UIDs, broken resource paths, or import errors.
- The full project compiles and imports cleanly.

This step confirms that the new scripts and scenes integrate properly with the rest of potty-secret.

---

## 3. Manual Editor Check — redaction_test.tscn Smoke Test

[x] user-run (verified 2026-05-14): Open the Godot editor, navigate to `potty-secret/scenes/redaction_test.tscn`, and press **F6** to run the scene.

Walk through the following checks (from the project spec):

- [x] user-run (verified 2026-05-14): **Layout check:** The scene displays a dark background, a paper panel on the left (~120-1400px horizontally, ~60-1020px vertically), and a UI panel on the right with controls.
  
- [x] user-run (verified 2026-05-14): **Text layout check:** The paper shows procedurally laid-out text (multiple words, readable content) and a directive label on the right listing two words marked as "illegal" (forbidden words).

- [x] user-run (verified 2026-05-14): **Marker cursor check:** When you move the mouse over the paper, a custom marker cursor appears (thick black circle or outline). When you move the mouse outside the paper, the OS cursor reappears. The custom cursor should be visible and responsive.

- [x] user-run (verified 2026-05-14): **Drawing and submit check:** 
  - Draw a marker stroke across one of the illegal words by clicking and dragging over it.
  - Press the **Submit** button (or use the bound key if configured).
  - A green tick should appear beside the word you marked.
  - Draw a stroke over a legal word and press Submit — a red cross should appear.

- [x] user-run (verified 2026-05-14): **Debug overlay toggle (SPACE):** Press **SPACE** to toggle the debug overlay on and off. When on, you should see:
  - Word bounding rectangles overlaid on the text
  - Tolerance bounds around the marker stroke
  - Sample dots indicating where the redaction was sampled
  - When toggled off, the overlay disappears.

- [x] user-run (verified 2026-05-14): **Marker mode toggle (M):** Press **M** to cycle between marker modes (LINE and BRUSH). The score label on the right should update to reflect the current mode.

**Expected outcome:** All smoke checks pass. The scene is fully functional, responsive, and mirrors the behavior of the source `document_scene.tscn`.

---

## 4. Manual Regression Check — game.tscn Still Works

[x] user-run (verified 2026-05-14): Open the Godot editor, navigate to `potty-secret/game.tscn` (the original main game scene), and press **F5** to run the full game.

- [x] user-run (verified 2026-05-14): Confirm that the existing game flow plays without errors or crashes.
- [x] user-run (verified 2026-05-14): Navigate through the normal game flow (intro, menu, main scene interactions, etc.) to ensure Phase 1 changes did not break any existing scenes or autoloads.

**Expected outcome:** The original game flow still works; no regressions introduced by Phase 1 changes.

---

## Summary

Run the four verification steps in order:

1. **Headless parse** (6 commands, each should exit 0)
2. **Full project import** (1 command, should exit 0)
3. **Manual editor redaction_test.tscn smoke checks** (7 checks, all must pass in the editor)
4. **Manual regression check** (open game.tscn, press F5, confirm original flow works)

If all four steps pass, Phase 1 is complete and ready for Phase 2.

---

## Notes for the User

- The `--check-only` commands on individual scripts may report parse warnings for class_name references that are resolved at full project import. This is normal and not a bug. The full project import (step 2) is the real validation.
- Steps 3 and 4 require interactive editor testing — they cannot be automated headlessly. Please run them yourself and confirm all criteria are met.
- If any step fails, note the error message and refer back to the relevant task in Phase 1 for debugging.
