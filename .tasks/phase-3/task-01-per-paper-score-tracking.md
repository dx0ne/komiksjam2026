---
id: task-01
title: game2.gd — per-paper score record + submit/new-document gating
status: pending
complexity: medium
blocked-by: ~
---

## Goal

Make `game2.gd` track each paper's pass/fail in a session-scoped list as
the player submits, and gate **New Document** so a paper cannot be
skipped without being reviewed.

After this task:

- A new field `paper_results: Array[bool]` (or equivalent) accumulates
  one entry per **Submit Review** press (true = paper passed, false =
  failed).
- The score label shows both the current paper's verdict (today's text)
  AND a running tally line: `Papers reviewed: N · passed: K`.
- **New Document** is disabled until the current paper has been
  submitted, then re-enabled. **Submit Review** is disabled after the
  paper is submitted, then re-enabled when New Document loads a fresh
  one. (Initial state: Submit enabled, New Document disabled.)
- The toilet handle (`gimme_toilet_btn`) still pulls a fresh batch and
  starts a new document at any time — pulling discards the in-progress
  paper without recording it. This matches phase 2's existing handle
  behaviour and keeps the player's control over the illegal set
  unchanged. (Justification: in the original `game.tscn`, papers
  pre-exist; in game2 they're generated on demand, so the toilet handle
  remains a "get me a fresh stack" action.)

This task does NOT change `_on_time_out` or `gimme_toilet_btn2` — those
stay stubs. Verdict + scene change is task-02.

## Context

### Files

- `potty-secret/game2.gd` — the only file edited.
- `.tasks/phase-3/phase.md` — exit criteria for the phase.
- `potty-secret/game.gd` — reference for the original session-tracking
  intent (`papers: Array[Paper]`, `paper.get_score()`).
- `potty-secret/paper.gd` — original `get_score()` returns true only if
  every redactable region was clicked AND every click was correct. The
  game2 equivalent is "the verdict from `_on_submit_pressed` was
  APPROVED".

### Current state in `game2.gd`

`_on_submit_pressed` (lines ~250-332) computes:

```gdscript
var verdict := "APPROVED" if score >= max_score * APPROVAL_FRACTION else "REVIEW FAILED"
```

This local `verdict` string is the source of truth — convert to a bool
(`var passed := score >= max_score * APPROVAL_FRACTION`) and append to
the session list.

`_generate_document` (lines ~168-190) is connected directly to
`NewDocumentButton.pressed` AND called from `new_tolilet_msgs` and
`_ready`. It calls `marker_layer.set_locked(false)` on every regenerate.

### Required changes in `game2.gd`

1. **New state field**: `var paper_results: Array[bool] = []`. Reset only
   in `_ready` (a session-long list).

2. **`_on_submit_pressed`**: at the end (after `marker_layer.set_locked(true)`),
   compute the bool verdict, `paper_results.append(passed)`, then update
   the score label to include the running tally line. Disable
   `submit_button` and enable `new_document_button` here.

3. **`_generate_document`**: at the end (the existing
   `_update_score_label("Drag the marker over forbidden words, …")`
   call), enable `submit_button` and disable `new_document_button`.

4. **`_ready`**: after the buttons are wired, set initial state —
   `submit_button.disabled = false`, `new_document_button.disabled =
   true`. (`paper_results` is already empty by virtue of being a fresh
   field.)

5. **Score label format**: keep the existing verdict block (verdict line,
   score line, full/half/missed counts, false count) and append the
   tally as a final line:
   `\nPapers reviewed: %d · passed: %d` % [paper_results.size(),
   paper_results.count(true)].

6. **Toilet handle path**: `new_tolilet_msgs` calls `_generate_document`
   at its end, which already resets the buttons via change (4). No
   special handling needed — pulling the handle mid-paper just discards
   the in-progress one without appending to `paper_results`. This is
   intentional and matches the spec note above.

### Out of scope

- `_on_time_out` and `gimme_toilet_btn2` stay as their phase-2 stubs.
- No changes to `WordManager`, `ending.tscn`, `clock.gd`, or any
  `.tscn`/`project.godot`/scene file.
- The keyboard `M` mode-toggle still overwrites the score label as it
  does today (it shows mode text, not a verdict — we're not preserving
  the tally there).
- Resetting `paper_results` mid-session (e.g. on toilet pull) is
  explicitly NOT done — the tally is the cumulative shift score.

## Acceptance Criteria

- [ ] Full project headless import succeeds:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit`
  exits 0 with no new warnings. (This is the authoritative parse check
  per phase-2 verification.md — the `--check-only --script game2.gd`
  command will fail with the documented WordManager autoload limitation
  and that is expected.)
- [ ] `game2.gd` defines `paper_results: Array[bool]` (or equivalent
  typed array of pass/fail records), populated in `_on_submit_pressed`,
  initialized empty.
- [ ] `_on_submit_pressed` disables `submit_button` and enables
  `new_document_button` after recording the result.
- [ ] `_generate_document` enables `submit_button` and disables
  `new_document_button`.
- [ ] `_ready` sets initial button enabled state (Submit enabled, New
  Document disabled) AFTER the first `new_tolilet_msgs()` /
  `_generate_document` call so the order of state writes is correct.
- [ ] The score label after submit includes a `Papers reviewed: N ·
  passed: K` line.
- [ ] No edits outside `potty-secret/game2.gd`.

## Notes

(To be filled in by the implementing subagent: what was changed, the
final exit codes from the headless commands, and any deviations from
the spec.)
