# Phase 2 Verification Checklist

This document provides the exact PowerShell commands and manual steps to verify that Phase 2 (Game scene integration — build game2.tscn) is complete and has not regressed the rest of the potty-secret project.

Godot binary path: `D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`

---

## 1. Headless Parse Check — game2.gd

The new game2.gd script must parse successfully with `--check-only`. Run this command from the project root directory where `potty-secret/` is located:

### game2.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd
```

**Expected outcome:** Exit code 0 (success). The script parses cleanly.

**Known limitation:** This script references the `WordManager` autoload class, which is not registered during single-script `--check-only` mode. This is an expected limitation of standalone syntax checking and **does not indicate a real problem**. The error resolves at full project import (step 2 below). The full project headless import is the authoritative parse check. Do not chase this as a bug.

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

This step confirms that the new game2.gd script and game2.tscn scene integrate properly with the rest of potty-secret.

---

## 3. Manual Editor Check — game2.tscn Smoke Test

[ ] user-run: Open the Godot editor, navigate to `potty-secret/game2.tscn`, and press **F6** to run the scene directly (do NOT repoint `run/main_scene`; run only game2.tscn).

Walk through the following checks:

- [ ] user-run: **Layout check:** Visible in the scene: background (Tlo), frame (Ramka), toilet handle on the left edge, clock on the lower-left, ashtray top-right, coffee, paperclips on the briefcase, and the paper region with text somewhere central. The UI panel (Submit / New Document / score / directive / title / clock label) is visible and not overlapping the decor in an obstructive way.

- [ ] user-run: **Initial document:** On scene start, the paper shows procedurally generated text with two illegal words from `WordManager`. The directive label lists those two illegal words.

- [ ] user-run: **Toilet handle pull:** Click `gimme_toilet_btn` once. Three toilet paper messages tween into position with three different words. The paper text regenerates so the illegal set matches the new toilet words. The directive label updates to the new illegal pair.

- [ ] user-run: **Marker cursor:** When you move the mouse over the paper, a custom thick black marker cursor appears. When you move the mouse outside the paper, the OS cursor reappears. The custom cursor should be visible and responsive.

- [ ] user-run: **Drawing and submit:** 
  - Drag a marker stroke across one of the illegal words by clicking and dragging over it.
  - Press the **Submit Review** button.
  - A green tick should appear beside the word you marked.
  - Drag a stroke over a legal word and press Submit — a red cross should appear.
  - Missed illegal words should blink red.
  - The score label should show verdict text (APPROVED / REVIEW FAILED) and counts.
  - **No scene change to ending.tscn should occur** (game2.tscn should remain active).

- [ ] user-run: **New Document:** Press **New Document**. Strokes clear, paper text regenerates (illegal set may stay the same — toilet pull is what changes the batch). Marker unlocks; player can draw again.

- [ ] user-run: **SPACE toggle (debug overlay):** Press **SPACE** to toggle the debug overlay on and off. When on, you should see:
  - Word bounding rectangles overlaid on the text
  - Tolerance bounds around the marker stroke
  - Sample dots indicating where the redaction was sampled
  - When toggled off, the overlay disappears.

- [ ] user-run: **M toggle (marker mode):** Press **M** to cycle between marker modes (LINE and BRUSH). The score label should update to reflect the current mode.

**Expected outcome:** All smoke checks pass. The scene is fully functional, responsive, and mirrors the behavior specified in the phase specification.

---

## 4. Manual Regression Check — game.tscn Still Works

[ ] user-run: Open the Godot editor, navigate to `potty-secret/game.tscn` (the original main game scene), and press **F5** to run the full game.

- [ ] user-run: Confirm that the existing game flow plays without errors or crashes.
- [ ] user-run: Navigate through the normal game flow (intro, menu, main scene interactions, etc.) to ensure Phase 2 changes did not break any existing scenes or autoloads.

**Expected outcome:** The original game flow still works; no regressions introduced by Phase 2 changes.

---

## Summary

Run the four verification steps in order:

1. **Headless parse** (1 command for game2.gd, should exit 0 — but see known limitation note)
2. **Full project import** (1 command, should exit 0) — **This is the authoritative parse check**
3. **Manual editor game2.tscn smoke checks** (9 checks, all must pass in the editor)
4. **Manual regression check** (open game.tscn, press F5, confirm original flow works)

If all four steps pass, Phase 2 is complete and ready for Phase 3.

---

## Notes for the User

- The `--check-only --script game2.gd` command will fail with "Identifier not found: WordManager" because autoloads are not registered in single-script mode. This is a **known limitation** (carried over from phase 1's cross-script `class_name` limitation). **Do not treat this as a blocking error.** The full project import (`--quit`) is the authoritative parse check and confirms that game2.gd integrates correctly when all autoloads and classes are loaded.

- Steps 3 and 4 require interactive editor testing — they cannot be automated headlessly. Please run them yourself and confirm all criteria are met by checking the `[ ] user-run` boxes.

- If any step fails, note the error message and refer back to the relevant task in Phase 2 for debugging.
