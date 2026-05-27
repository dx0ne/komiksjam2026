# Phase 7 Manual Playtest Results

**Test Date:** TBD (deferred to human run)  
**Tester:** TBD  
**Environment:** Godot Editor (game2.tscn)

---

## Scenario 1: Teaching Phase (0–60s): Clean Win on Paper #1

### Setup
- Open `game2.tscn` in the Godot editor.
- Start the game (press Play).
- Observe paper #1 + intel strip as the game initializes.

### Steps
1. On paper #1, count the **planted word boxes** (2–3 template slots).
2. Read the intel strip in the top-right corner (the three forbidden words displayed on the toilet).
3. Verify that **every** planted word on the paper matches a word on the intel strip (identical rendering, no obfuscation).
4. Drag the marker across each planted word, covering ≥50% of the word box.
5. Release the marker after marking each planted word.
6. Observe the floating popup labels as each word is marked.

### Expected
- Intel strip displays canonicals only (e.g. "ALIENS", "ELVIS") — no typos, no synonyms.
- Paper renders planted words identically to the intel (no obfuscation, no typos).
- Every planted slot's canonical appears verbatim on the intel strip.
- Marking each planted word fully (100% coverage) earns a `+2` popup.
- After marking all planted words, a stamp appears briefly on the paper before it fades.
- Pass criterion: no obfuscation, no decoys, marking is straightforward — the teaching round should feel like a guaranteed win.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 2: Light Phase (60–120s): Intel Obfuscated, Paper Canonical, Few Obvious Decoys

### Setup
- Continue from scenario 1 without restarting the shift.
- Advance elapsed time past 60s by marking words and pulling the lever.
- Once elapsed time shows 60–120s (check the clock), wait for (or trigger) a new paper spawn.

### Steps
1. Observe the new paper in the light phase.
2. Compare the planted words on the paper to the intel strip:
   - Read the planted words on the paper (should be canonical, e.g. "ALIENS").
   - Read the intel strip (will show obfuscation, e.g. "ALOIENS" instead of "ALIENS", or "THEM" instead of "ALIENS").
3. Look for the **appended noise sentence** at the bottom of the paper — it should contain 1–2 decoy words (words that are NOT the planted canonicals).
4. Verify that the decoys in the noise sentence are visibly similar to the intel words (same length ±1, shared letters, but NOT canonicals of intel words).
5. Mark one of the correct planted words fully (100% coverage), comparing by canonical concept (not spelling):
   - Identify the canonical concept on the intel (e.g. "THEM" is a synonym for "ALIENS").
   - Find the matching canonical on the paper (e.g. "ALIENS").
   - Mark it.
6. Observe the `+2` popup and the shift score increase.
7. Mark one of the decoys (a word from the noise sentence that is NOT a canonical match).
8. Observe the `-0.5` popup and red stroke color.

### Expected
- Intel strip displays typos or synonyms (e.g. "ALOIENS" instead of "ALIENS", or "THEM" instead of "ALIENS").
- Paper still renders canonicals verbatim (e.g. "ALIENS" on paper, but intel shows "ALOIENS").
- 1–2 decoy words appended in a noise sentence at the end of the paper.
- Decoys are visibly similar (length, shared letters) to intel words but are NOT canonicals of intel words.
- Marking a correct canonical: `+2` popup, green stroke, shift score increases.
- Marking a decoy: `-0.5` popup, red stroke, penalty badge increments on the post-it.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 3: Full Phase (120–180s): Paper and Intel Both Obfuscated, Close-Call Decoys

### Setup
- Continue the same shift.
- Advance elapsed time past 120s (mark words, pull the lever several times).
- Once elapsed time shows 120–180s, wait for (or trigger) a new paper spawn.

### Steps
1. Observe the new paper in the full phase.
2. Inspect the planted words:
   - The paper might render planted slots as typos (e.g. "ALOIENS" where the canonical is `aliens`), not just canonicals.
3. Read the intel strip:
   - Intel now mixes typos and synonyms (e.g. one word might show "ALOIENS", another "THEM").
4. Look at the noise sentence:
   - 2–4 decoys should be present.
   - Decoys are close-call lookalikes (edit distance ≤ 2 from intel variants, or visually very similar).
5. Deliberately mark a decoy (a word in the noise sentence that is NOT a canonical match):
   - Even if it looks very close to an intel variant, if it is not a canonical match, it is a decoy.
   - Observe the `-0.5` popup and red stroke.
6. Mark a correct planted word:
   - Use canonical-level matching: identify the canonical on intel, find it on the paper (even if spelled differently), mark it.
   - Observe the `+2` (or `+1` for partial coverage) popup and green stroke.

### Expected
- Paper rendering can include typos (e.g. "ALOIENS" where the canonical is `aliens`).
- Intel mixes typos and synonyms (complex obfuscation).
- 2–4 decoys per paper, visually close to intel display variants (edit distance ≤ 2).
- **Critical:** Even at full obfuscation, every paper is still solvable. The player must read both sides carefully and match by concept (canonical), not by spelling.
- Marking a decoy when intel is heavily obfuscated should feel like a real eye-skill failure, not a coin flip.
- Marking correct canonicals yields `+1`/`+2`; marking decoys yields `-0.5`.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 4: Pull Lever Advances Paper (No -2s Clock Cost, No Submit Penalty)

### Setup
- From any active paper (any phase).
- Ensure at least one planted word is marked (to test that score is locked).

### Steps
1. Note the current `shift_score` on the post-it (top-right).
2. Note the current clock value (elapsed time).
3. Click the toilet handle (the pull lever).
4. Observe the transition:
   - Handle bounces.
   - Current paper fades/tweens away.
   - New paper + new intel appear.
5. After the new paper fully appears, note the `shift_score` again.
6. Check the clock value again.

### Expected
- New paper + new intel appear in one smooth transition (no -2s clock cost visible).
- The `shift_score` on the post-it is exactly what was earned at mark-time (no -0.5 deductions for unmarked planted slots).
- Clock shows no deduction (or only within normal tween jitter — verify by comparing before/after values).
- No submit-penalty popup appears during the transition (submit penalty model is removed).

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 5: Briefcase is Non-Interactive

### Setup
- From any active paper (any phase).

### Steps
1. Locate the briefcase sprite (the `Teczka` / `Teczka2` area on the background, visible as decorative art between the paper and the margin).
2. Click directly on the briefcase (try both the left and right briefcase sprite).
3. Observe whether anything happens.

### Expected
- Nothing happens.
- No new paper spawns.
- No penalty popup appears.
- No score change.
- The cursor may or may not change on hover (cosmetic, out of scope).
- The briefcase is purely visual scenery (non-interactive).

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 6: Paper Spawn Originates from the Briefcase

### Setup
- Start a fresh shift (or continue an existing one).
- Pull the lever multiple times to spawn several papers.

### Steps
1. Watch the screen as a new paper spawns after pulling the lever.
2. Observe the paper's initial position and movement:
   - The new paper should visibly tween from somewhere near the briefcase position (between the two `Teczka` sprites, roughly at coordinates 1901–1939, 466–457) into the working desk position.
   - The tween should take approximately 0.35s.
   - The paper should have a slight rotation during the tween.
   - The first paper of the shift (when the game starts) does NOT animate — it just appears instantly at the working desk position.
3. Verify the animation plays smoothly without blocking input.

### Expected
- Each new paper (after the first) visibly tweens from the briefcase position into the working desk position over ~0.35s.
- Tween includes a slight rotation for visual polish.
- The first paper of the shift appears instantly (no animation).
- Animation does not block input — the paper is markable as soon as the tween finishes.
- The visual effect reinforces that papers originate from the briefcase.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 7: Decoy Mismarking Penalty + Stroke Color

### Setup
- From a light or full phase paper (scenario 2 or 3) with visible decoys in the appended noise sentence.

### Steps
1. Identify a decoy word in the noise sentence (a word that is NOT a canonical match for any intel word).
2. Drag the marker across the decoy word, covering ≥50% of the word box.
3. Release the marker.
4. Observe the visual feedback:
   - A floating `-0.5` popup should appear at the decoy's position, then fade.
   - The stroke should render in RED (not the marker's normal color).
   - The penalty badge on the post-it (red badge) should increment by 1.
   - The `shift_score` on the post-it should drop by 0.5.

### Expected
- Decoy mismarking yields `-0.5` popup (red color) at the decoy's position.
- Stroke color is red (distinctly different from the green stroke used for correct marks).
- Penalty badge on the post-it increments.
- Shift score drops by 0.5.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 8: Stamp on Perfect Redaction (Carry-over from Phase 6)

### Setup
- From a light phase paper (scenario 2 recommended).
- Mark every planted slot fully (100% coverage).
- Ensure no decoys are marked (zero penalties).

### Steps
1. After marking all planted words fully, click the toilet handle (pull the lever).
2. Observe the paper before it tweens away:
   - A stamp should briefly appear on the paper, indicating a perfect redaction.
   - The stamp should be visible for a moment before the paper fades/tweens to make room for the next one.

### Expected
- Stamp briefly visible on the paper after pulling the lever (perfect redaction visual feedback).
- Stamp appears before the paper tweens away to make room for the next one.
- This mechanic carries over from phase 6 unchanged — it provides visual confirmation of a well-executed round.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Scenario 9: Shift End: Ending Screen Reflects At-Mark Score Only

### Setup
- From any shift in progress.
- Accumulate some marks and penalties to test score logic.

### Steps
1. Press debug key `7` (skip_to_ending) to jump to the ending screen.
   - Alternatively, let the 180s clock run out naturally (wait ~3 minutes).
2. Observe the transition to the ending scene.
3. Check the ending screen:
   - If `shift_score > 0.0`, the screen should show "good ending" (`WordManager.good_ending = true`).
   - If `shift_score ≤ 0.0`, the screen should show "bad ending" (`WordManager.good_ending = false`).
4. Verify that no submit-penalty popup is fired during the transition:
   - No floating `-0.5` labels should appear as the shift ends.
   - The score shown on the ending screen is exactly the `shift_score` accumulated at mark-time (no additional penalties).

### Expected
- Ending scene loads smoothly.
- `WordManager.good_ending` is `true` iff `shift_score > 0.0`.
- No submit-penalty popup is fired during the transition to the ending screen (submit-penalty model is removed).
- Ending screen score reflects at-mark accumulated score only, not any hidden deductions.

### Observed
_Deferred — needs human run_

### Pass/Fail
?

---

## Summary

| Scenario | Pass/Fail | Notes |
|----------|-----------|-------|
| 1. Teaching phase clean win (0–60s) | ? | Deferred |
| 2. Light phase obfuscation (60–120s) | ? | Deferred |
| 3. Full phase obfuscation (120–180s) | ? | Deferred |
| 4. Pull lever advances paper (no clock cost) | ? | Deferred |
| 5. Briefcase is non-interactive | ? | Deferred |
| 6. Paper spawn from briefcase animation | ? | Deferred |
| 7. Decoy mismarking penalty + red stroke | ? | Deferred |
| 8. Stamp on perfect redaction | ? | Deferred |
| 9. Ending screen at-mark score only | ? | Deferred |

---

## Notes

### Why Deferred?

Godot is not available in the current Windows environment (no `godot` executable in PATH, not found in Program Files). The subagent cannot launch the Godot editor to run the playtest interactively. The checklist above is **structured and ready for human execution**—each scenario has clear, terse steps and explicit expected outcomes.

A human tester can:
1. Open the Godot editor on a machine with Godot installed.
2. Load `potty-secret/game2.tscn`.
3. Walk through each scenario in sequence (recommend scenarios 1–3 in the teaching→light→full phase progression during a single shift, 4–6 testing the pull/briefcase/spawn mechanics in a second shift, 7–9 testing penalties and endings in a third shift).
4. Fill in the **Observed** and **Pass/Fail** columns.

All critical phase-7 exit-criteria are covered:
- ✓ Teaching phase clean win (no obfuscation at 0–60s)
- ✓ Light phase intel obfuscation (60–120s), paper still canonical
- ✓ Full phase paper-and-intel obfuscation (120–180s)
- ✓ Decoy injection and mismarking penalty
- ✓ Pull lever as the only advance action (no clock cost, no submit penalty)
- ✓ Briefcase becomes non-interactive scenery
- ✓ Teczka-anchored spawn animation
- ✓ Stamp on perfect redaction (carry-over)
- ✓ Ending screen reflects at-mark score (no submit penalty)

**Next step (by human):** Execute the checklist, record results, and update this file with Pass/Fail outcomes.
