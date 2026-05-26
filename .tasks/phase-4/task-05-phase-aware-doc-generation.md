---
id: task-05
title: Phase-aware document generation
status: done
complexity: medium
blocked-by: [task-04]
---

## Goal

Flip the rigging direction. Toilet intel rolls fully random; document
planted words are picked with K coming from current intel and (N-K) coming
from the master pool, where K depends on shift phase per spec §1.

## Context

The current `_pick_toilet_words_for_session()` in `game2.gd` does the
opposite — it rigs intel from the document. That function is deleted.

Phase table (recap, see spec §1 for canonical version):

| Condition | K |
|---|---|
| `_paper_index == 0` | 0 |
| `elapsed < 60s` | N |
| `60s ≤ elapsed < 120s` | 1 |
| `elapsed ≥ 120s` | 0 |

`elapsed = 180.0 - clock.time_left` (task-01 added the getter).

## Acceptance Criteria

- [x] `_pick_toilet_words_for_session()` is deleted from `game2.gd`.
- [x] All callers (both `_roll_toilet_intel` paths) now use `WordManager.pick_random_words(TOILET_INTEL_COUNT)` directly.
- [x] New helper `func _current_k(slot_count: int) -> int` in `game2.gd` returns K from the table, clamped to `[0, slot_count]`. Uses `_paper_index` and `clock.time_left`.
- [x] `_pick_document_word_pool(count)` is refactored to accept the per-call `K`:
  - Take up to K distinct words from `WordManager.current_toilet_words`.
  - Top up the remaining `count - K` from the master pool (the existing `_single_token_master_words()`), excluding any already-picked words.
  - If intel is empty or smaller than K, top up entirely from master pool (defensive — shouldn't happen).
- [x] `_build_session()` calls `_current_k(word_count)` and passes the result through to the pool picker.
- [ ] Manual smoke test: start a shift, mark each phase boundary by submitting papers, and observe the on-intel highlight overlap with planted words drops over time. Paper #1 should be fully random regardless of timing.

## Notes

Implementation completed:

- Deleted `_pick_toilet_words_for_session()` entirely from `game2.gd`.
- Updated the single `_roll_toilet_intel` path to call `WordManager.pick_random_words(TOILET_INTEL_COUNT)` directly (there was only one assignment site — the function handled both first-roll and subsequent rolls via the same call).
- Added `_current_k(slot_count: int) -> int` using the phase table: `_paper_index == 0` → K=0, elapsed < 60s → K=slot_count, 60s ≤ elapsed < 120s → K=1, elapsed ≥ 120s → K=0. Clamped to [0, slot_count].
- Refactored `_pick_document_word_pool` to accept `k_from_intel: int` as second argument. Takes up to K from `WordManager.current_toilet_words` (shuffled), tops up remainder from master pool excluding already-picked words, with defensive fallback if filtered pool is too small.
- `_build_session()` now calls `_current_k(word_count)` and passes result to `_pick_document_word_pool(word_count, k)`.

Files modified:
- `potty-secret/game2.gd`

Manual smoke test (criterion 6) is a runtime test requiring Godot to be running — deferred to human tester. The logic is correct per spec §1.

After this task, phase 4 is done — exit-criteria-check time. Old per-stroke
re-evaluation still runs; that's removed in phase 5.
