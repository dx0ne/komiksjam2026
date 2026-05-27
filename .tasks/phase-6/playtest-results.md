# Phase 6 Manual Playtest Results

**Test Date:** TBD (deferred to human run)  
**Tester:** TBD  
**Environment:** Godot Editor (game2.tscn)

---

## Scenario 1: First Paper Clean Win (K=N, teaching round)

### Setup
- Open `game2.tscn` in the Godot editor.
- Start the game (press Play).
- Intel rolls in `_ready` BEFORE the first paper spawns, so paper #1 lands with K=N (all planted words drawn from intel).

### Steps
1. Observe the first memo on screen.
2. Look at the toilet strip — it shows 3 forbidden words.
3. Count the **planted word boxes** (the 2–3 template slots on the memo).
4. For each planted word, check whether it appears in the toilet strip.
5. Verify that **EVERY** planted word is in the toilet strip (i.e. on intel).
   - Expected: The player can mark all planted words without pulling the toilet handle — a clean win that teaches the mark-and-submit flow.

### Expected
- All planted words on paper #1 appear on the toilet strip.
- Marking each planted fully yields a `+2` popup; submitting earns the stamp without any reroll.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 2: Easy Phase (0–60s): All Planted Words on Intel

### Setup
- Continue from scenario 1 or restart.
- Clock shows elapsed time 0–60s.

### Steps
1. Pull the toilet handle once (if not already done in scenario 1). The toilet intel rerolls to 3 new forbidden words.
2. Verify the post-it now shows the new toilet trio.
3. Wait for the game to spawn a **second paper** (or mark words on the first to trigger conditions for "paper ready to submit").
4. **Before submitting/briefing**, look at the second paper's planted words.
5. Cross-check each planted word slot against the **current toilet strip** (top-right corner).
6. Count how many planted words are in the intel list.

### Expected
- **All** planted words on the second paper are present in the current toilet intel (K=N for 0–60s phase).
- Post-it shows "N/N" (all planted words are on-intel, so all can earn points if marked).
- When you later mark a planted+on-intel word, a `+1` or `+2` popup appears.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 3: Mixed Phase (60–120s): Exactly One Planted Word on Intel

### Setup
- Continue the same shift (do not restart).
- Clock shows elapsed time between 60–120s.
- (You may need to delay marking words or skip papers to reach this window.)

### Steps
1. Wait for (or trigger) a paper spawn between 60–120s elapsed time.
   - Hint: If you haven't reached 60s yet, mark/submit papers quickly to advance time.
2. Once a new paper appears in the 60–120s window, check the planted words against the current toilet intel.
3. Count how many planted words appear in the forbidden list.

### Expected
- **Exactly 1** planted word is on intel.
- The remaining planted words (N–1) are from the master pool, not on intel.
- Post-it shows "0/N" initially (no words marked yet), but once you mark the one on-intel word, it updates to "1/N".

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 4: Random Phase (120–180s): No Planted Words on Intel

### Setup
- Continue the same shift.
- Clock shows elapsed time 120–180s (late game, hardest phase).

### Steps
1. Advance time to the 120–180s window (mark/submit papers to speed up, or wait).
2. When a new paper spawns after 120s elapsed, check the planted words against the current toilet intel.
3. Verify that **none** of the planted words match the forbidden trio.

### Expected
- **Zero** planted words on intel (K=0).
- All planted words come from the master pool.
- If you mark any planted word, no `+1`/`+2` popup appears (since they are not on intel, they don't score).
- Post-it remains "0/N" throughout (no points available on this paper).

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 5: At-Mark Scoring — Partial and Full Coverage

### Setup
- From any active paper in the easy phase (0–60s recommended for guaranteed on-intel words).

### Steps
1. **Partial coverage (half):**
   - Find a planted word that is in the current intel.
   - Drag the marker across it, covering approximately 50–70% of the word box.
   - Release the marker (complete the stroke).
   - **Observe:** A floating `+1` label appears at the word's center and drifts upward, fading out.
   - **Verify:** The post-it X increases by 1 (e.g., 0/N → 1/N).
   - The stroke color shows as **green accent** (positive delta).

2. **Full coverage (100%):**
   - Find another planted+on-intel word.
   - Drag the marker across it, covering 100% of the word box.
   - Release.
   - **Observe:** A floating `+2` label appears.
   - **Verify:** The post-it X increases by 1.
   - The stroke color shows as **green accent**.

3. **Re-stroke the same word (full):**
   - Drag the marker over the same full-coverage word again.
   - Release.
   - **Observe:** **No popup appears.**
   - **Verify:** Post-it X **does not change** (score is locked once a word reaches "full" state).
   - No new popup.

### Expected
- Partial coverage → `+1` popup + post-it updates.
- Full coverage → `+2` popup + post-it updates.
- Re-stroke same word → no popup, no score change (locked state).
- Stroke color is green for positive deltas.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 6: Wrong Mark Penalty

### Setup
- From an active paper.

### Steps
1. Find a **clean word** on the memo (not in the planted slots and not in the current intel).
2. Drag the marker across it, covering ≥50% of the word.
3. Release.
4. **Observe:**
   - A floating `-0.5` label appears at the word's center (red color).
   - The word **stroke turns red** (visual feedback).
   - The penalty counter on the post-it (the red badge) increments by 1.
5. Verify the shift score on the post-it decreases by 0.5.

### Expected
- Non-planted/non-intel word marked → `-0.5` popup (red).
- Stroke color is **red**.
- Post-it penalty badge increments.
- Shift score drops by 0.5.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 7: Submit Penalty (Unscored Planted Words)

### Setup
- From an active paper.
- Ensure the paper has at least one planted word that is **not yet marked** (still in "untouched" state).
  - Recommendation: In the easy phase, mark only 1 of 2 planted words. Leave the other untouched.

### Steps
1. Click the **briefcase** button (send to briefing).
2. **Before the paper advances**, observe the screen:
   - A floating `-0.5` label appears for each untouched planted word.
   - The shift score on the post-it briefly shows the penalty deduction before the paper changes.
3. Verify that the shift score dropped by 0.5 per unscored planted word.
4. A new paper will appear after the penalty is applied.

### Expected
- Unscored (untouched) planted words trigger `-0.5` popup at submit time.
- Shift score decreases by 0.5 per unscored word.
- Paper advances after penalty.
- The tension mechanic is visible: "submit now = lose points" vs. "reroll = hope for intel."

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 8: Negative Shift Score Display

### Setup
- Continue the same shift.
- Accumulate enough wrong marks or unscored planted words to drive shift_score below 0.

### Steps
1. Deliberately mark clean (non-target) words on several papers, or leave many planted words untouched at submit time.
2. Watch the post-it shift score as it accumulates penalties.
3. Once shift_score drops below 0 (e.g., –1.5, –2.0):
   - **Observe:** The shift score label on the post-it displays **without a leading `+` sign**.
   - The number is preceded by a **minus sign** (e.g., `–1.5`, not `+–1.5`).

### Expected
- Negative shift score displays with a leading minus (e.g., `-1.5`).
- No `+` sign for negative values.
- The UI correctly indicates that the player is "in the red."

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 9: Popup Z-Order (Visibly Above Ink)

### Setup
- From an active paper with visible strokes.

### Steps
1. Mark several words on the memo (create visible marker strokes).
2. Observe the floating popups as they appear (+1, +2, or -0.5).
3. **Critical check:** Verify that each popup label is **visibly above** the marker ink (strokes), not underneath.
   - The popup should be readable and stand out; marker ink should not obscure it.

### Expected
- Popups render on top of all strokes (correct z-order/draw order).
- Popups are clearly readable and visually prominent.
- Marker ink does not overlap or hide the popup text.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Summary

| Scenario | Pass/Fail | Notes |
|----------|-----------|-------|
| 1. First paper clean win (K=N) | ? | Deferred |
| 2. Easy phase (0–60s) | ? | Deferred |
| 3. Mixed phase (60–120s) | ? | Deferred |
| 4. Random phase (120–180s) | ? | Deferred |
| 5. At-mark scoring | ? | Deferred |
| 6. Wrong mark penalty | ? | Deferred |
| 7. Submit penalty | ? | Deferred |
| 8. Negative shift score | ? | Deferred |
| 9. Popup z-order | ? | Deferred |

---

## Notes

### Why Deferred?

Godot is not available in the current Windows environment (no `godot` executable in PATH, not found in Program Files). The subagent cannot launch the Godot editor to run the playtest interactively. The checklist above is **structured and ready for human execution**—each scenario has clear, terse steps and explicit expected outcomes. 

A human tester can:
1. Open the Godot editor on a machine with Godot installed.
2. Load `potty-secret/game2.tscn`.
3. Walk through each scenario in sequence (recommend scenarios 1–4 in a single shift, 5–8 in a second shift, 9 as a final check).
4. Fill in the **Observed** and **Pass/Fail** columns.

All critical phase-6 exit-criteria are covered:
- ✓ Paper #1 clean win (K=N — intel rolls before paper spawns)
- ✓ Difficulty phases: easy (K=N), mixed (K=1), random (K=0)
- ✓ Popup spawning and colors (+1, +2, -0.5)
- ✓ Stroke color feedback (green for positive, red for negative)
- ✓ Submit penalty visible
- ✓ Negative shift score display
- ✓ Popup z-order (above ink)

**Next step (by human):** Execute the checklist, record results, and update this file with Pass/Fail outcomes.
