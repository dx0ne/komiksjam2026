# Phase 3 Verification Checklist

This document provides the exact PowerShell commands and manual steps to verify that Phase 3 (Scoring & verdict wiring) is complete and has not regressed the rest of the potty-secret project.

Godot binary path: `D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe`

---

## 1. Headless Parse Check — game2.gd

The updated game2.gd script must parse successfully with `--check-only`. Run this command from the project root directory where `potty-secret/` is located:

### game2.gd
```powershell
& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd
```

**Expected outcome:** Exit code 0 (success). The script parses cleanly.

**Known limitation (carry-over):** This script references the `WordManager` autoload class, which is not registered during single-script `--check-only` mode. This produces:

```
SCRIPT ERROR: Compile Error: Identifier not found: WordManager
   at: GDScript::reload (res://game2.gd:153)
ERROR: Failed to load script "res://game2.gd" with error "Compilation failed".
```

This is an expected, documented limitation of standalone syntax checking and **does not indicate a real problem**. Exit code 1 in this mode is acceptable — the full project headless import (step 2) is the authoritative parse check. Do not chase this as a bug.

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

This step confirms that the updated game2.gd script and game2.tscn scene integrate properly with the rest of potty-secret, including all autoloads and scoring additions from Phase 3.

---

## 3. Manual Editor Check — game2.tscn Smoke Test

[ ] user-run: Open the Godot editor, navigate to `potty-secret/game2.tscn`, and press **F6** to run the scene directly (do NOT repoint `run/main_scene`; run only game2.tscn).

### Carried-forward phase-2 checks

Walk through the following checks first (these must continue to pass after Phase 3 changes):

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
  - **No scene change to ending.tscn should occur** immediately after a single submit (game2.tscn should remain active).

- [ ] user-run: **New Document:** Press **New Document**. Strokes clear, paper text regenerates. Marker unlocks; player can draw again.

- [ ] user-run: **SPACE toggle (debug overlay):** Press **SPACE** to toggle the debug overlay on and off. When on, you should see word bounding rectangles, tolerance bounds, and sample dots. When toggled off, the overlay disappears.

- [ ] user-run: **M toggle (marker mode):** Press **M** to cycle between marker modes (LINE and BRUSH). The score label should update to reflect the current mode.

### Phase-3-specific checks

- [ ] user-run: **Submit gating:** Before pressing **Submit Review**, the **New Document** button is visibly disabled (greyed out). After pressing Submit, **New Document** becomes enabled and **Submit Review** becomes disabled. Confirm this gating works each cycle.

- [ ] user-run: **Tally line:** After pressing Submit, the score label includes a running tally line such as `Papers reviewed: 1 · passed: 0` (or `passed: 1` if the player correctly redacted all illegal words). Submit a second document and confirm the tally increments: e.g. `Papers reviewed: 2 · passed: 1`.

- [ ] user-run: **Briefcase guard (current paper not submitted):** Without pressing Submit on the current paper, click `gimme_toilet_btn2` (the briefcase button). Nothing should happen visually; the scene should NOT change to ending.tscn. The Output console (if open) should show a line such as `briefcase pressed but current paper not yet submitted — ignored`.

- [ ] user-run: **Briefcase trigger (good ending):** Press Submit on a paper where every illegal word was correctly redacted (result: APPROVED). Then click the briefcase. The scene should change to `ending.tscn` and the **good** ending video plays.

- [ ] user-run: **Briefcase trigger (bad ending):** Restart `game2.tscn` (press F6 again). Press Submit on a paper without redacting any illegal words (result: REVIEW FAILED). Click the briefcase. The scene should change to `ending.tscn` and the **bad** ending video plays.

- [ ] user-run (optional, slow): **Clock timeout (bad ending fallback):** Restart `game2.tscn`. Do NOT submit anything. Wait for the clock to run down (180 s by default). Confirm the scene changes to `ending.tscn` and plays the bad ending. This check is optional due to the long wait time.

- [ ] user-run: **`skip_to_ending` debug shortcut:** At any time during play, press **7** (the key bound to the `skip_to_ending` action in `project.godot`, `physical_keycode=55`). Confirm the scene changes to `ending.tscn`. The good/bad video should reflect the current `paper_results` accumulated so far (good if all submitted papers passed and at least one was submitted, bad otherwise).

---

## 4. Manual Regression Check — game.tscn Still Works

[ ] user-run: Open the Godot editor, navigate to `potty-secret/game.tscn` (the original main game scene), and press **F5** to run the full game.

- [ ] user-run: Confirm that the existing game flow plays without errors or crashes.
- [ ] user-run: Navigate through the normal game flow (intro, menu, main scene interactions, clock timeout or briefcase trigger, ending transition) to ensure Phase 3 changes did not break any existing scenes or autoloads.
- [ ] user-run: Confirm `ending.tscn` still plays the correct video based on `WordManager.good_ending` as set by the original game logic.

**Expected outcome:** The original game flow still works; no regressions introduced by Phase 3 changes.

---

## Summary

Run the four verification steps in order:

1. **Headless parse** (1 command for game2.gd — expected exit 1 due to WordManager autoload limitation; see note)
2. **Full project import** (1 command, must exit 0) — **This is the authoritative parse check**
3. **Manual editor game2.tscn smoke checks** (15 checks: 8 carried from phase 2, 7 phase-3-specific; all must pass in the editor)
4. **Manual regression check** (open game.tscn, press F5, confirm original flow works)

If all four steps pass, Phase 3 is complete and ready for close-out.

---

## Notes for the User

- The `--check-only --script game2.gd` command will fail with "Identifier not found: WordManager" (exit code 1) because autoloads are not registered in single-script mode. This is a **known limitation** (carried over from phases 1 and 2). **Do not treat this as a blocking error.** The full project import (`--quit`) is the authoritative parse check.

- The `skip_to_ending` debug shortcut is bound to the **7** key (`physical_keycode=55, unicode=55` in `project.godot` `[input]` section). Press it at any point in `game2.tscn` to jump immediately to `ending.tscn` without waiting for the clock.

- Steps 3 and 4 require interactive editor testing — they cannot be automated headlessly. Please run them yourself and confirm all criteria are met by checking the `[ ] user-run` boxes.

- If any step fails, note the error message and refer back to the relevant task in Phase 3 for debugging.
