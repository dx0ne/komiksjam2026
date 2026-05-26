---
id: task-05
title: Phase-aware document generation
status: in-progress
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

- [ ] `_pick_toilet_words_for_session()` is deleted from `game2.gd`.
- [ ] All callers (both `_roll_toilet_intel` paths) now use `WordManager.pick_random_words(TOILET_INTEL_COUNT)` directly.
- [ ] New helper `func _current_k(slot_count: int) -> int` in `game2.gd` returns K from the table, clamped to `[0, slot_count]`. Uses `_paper_index` and `clock.time_left`.
- [ ] `_pick_document_word_pool(count)` is refactored to accept the per-call `K`:
  - Take up to K distinct words from `WordManager.current_toilet_words`.
  - Top up the remaining `count - K` from the master pool (the existing `_single_token_master_words()`), excluding any already-picked words.
  - If intel is empty or smaller than K, top up entirely from master pool (defensive — shouldn't happen).
- [ ] `_build_session()` calls `_current_k(word_count)` and passes the result through to the pool picker.
- [ ] Manual smoke test: start a shift, mark each phase boundary by submitting papers, and observe the on-intel highlight overlap with planted words drops over time. Paper #1 should be fully random regardless of timing.

## Notes

The existing `_pick_document_word_pool` reshuffles the master pool. Keep
that as the fallback path. Suggested signature:

```gdscript
func _pick_document_word_pool(count: int, k_from_intel: int) -> Array[String]:
```

Update the existing single caller in `_build_session()`.

After this task, phase 4 is done — exit-criteria-check time. Old per-stroke
re-evaluation still runs; that's removed in phase 5.
