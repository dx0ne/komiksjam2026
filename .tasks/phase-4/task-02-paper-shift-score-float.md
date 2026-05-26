---
id: task-02
title: paper.set_shift_score accepts float, shows negatives
status: pending
complexity: low
blocked-by: ~
---

## Goal

Loosen `GamePaper.set_shift_score`'s parameter to `float` and change the
display rule so the player sees positive, zero, and negative shift totals.

## Context

`potty-secret/paper.gd` currently:

```gdscript
func set_shift_score(total_correct: int) -> void:
    ...
    if total_correct > 0:
        %pointsLabel_good.text = "+%d" % total_correct
    else:
        %pointsLabel_good.text = ""
```

New scoring is float-based and can go negative (spec §5). The player needs
to see a negative running score — it's the only signal that they're bleeding.

## Acceptance Criteria

- [ ] Signature is `func set_shift_score(score: float) -> void:`.
- [ ] `score > 0` → `"+%.1f" % score` (e.g. `+28.5`).
- [ ] `score < 0` → `"%.1f" % score` (the `-` is part of the formatted number, e.g. `-1.5`).
- [ ] `score == 0` → empty string (unchanged from today).
- [ ] Existing caller in `game2.gd` (`active_paper.set_shift_score(WordManager.shift_correct_illegal)`) still compiles; passing the old int field is fine because int → float widens.

## Notes

After task-04 lands, the caller passes `WordManager.shift_score` (float).
This task on its own should still leave the project compiling and runnable
with the old int field — int → float conversion is implicit in GDScript.
