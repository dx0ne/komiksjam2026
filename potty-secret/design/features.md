# Feature index

Living catalog of gameplay and desk-atmosphere systems. For the core shift loop, scoring, and difficulty phases see [`GAME_LOOP.md`](../GAME_LOOP.md). For original feature specs see [`docs/superpowers/specs/`](../docs/superpowers/specs/).

Maintenance rules for this file: [`AGENTS.md`](../AGENTS.md) § Feature index.

---

## Quick index

| Feature | Owner | Triggers | Affects |
|---------|-------|----------|---------|
| [Shift clock](#shift-clock) | `clock.gd` | `start_shift()`, timer tick | Progress bar, clock hand, light flicker mode |
| [Difficulty phases](#difficulty-phases) | `game2.gd` | Elapsed shift time | Paper variants, toilet intel, decoys |
| [Onboarding](#onboarding) | `game2.gd`, `onboarding_content.gd`, `document_scenes.gd` | First launch | UI visibility, scripted papers, progress save |
| [Topic intro newspaper](#topic-intro-newspaper) | `document_scenes.gd`, `topic_content.gd`, `paper.gd` | First shift per topic | Mark targets on desk paper; blocks shift until redacted |
| [Custom document scenes](#custom-document-scenes) | `scenes/documents/`, `scenes/newspapers/` | Scripted spawn | Background, text area, post-it layout per scene |
| [Point light flicker](#point-light-flicker) | `scripts/flicker_light.gd` | Clock time remaining | Light energy, `flicker_off` / `flicker_on` signals |
| [Desk shadows](#desk-shadows) | `game2.gd` | Light flicker, cofefe drag | `KawaCien`, `PopielniczkaCien` alpha |
| [Cofefe mug](#cofefe-mug) | `scenes/desk_props/cofefe.gd` | Click / drag | 1 sip/shift; +10s & +1 twitch force; `Inside` empties on use; smear, marker lock |
| [Papieros cigarette](#papieros-cigarette) | `scenes/desk_props/papieros.gd` | One click while unlit | −1 twitch force once; ~6 s fuse then stub |
| [Toilet handle attract](#toilet-handle-attract) | `game2.gd` | Idle 4s after handle visible | Handle sway + flash |
| [Rubber fly marker](#rubber-fly-marker) | `game2.gd` + `%Rubber` scene | Onboarding steps, stroke idle | Marker prop animation |
| [Marker review blink](#marker-review-blink) | `scripts/marker_layer.gd` | Review stroke colors applied | Tick/cross overlay pulse |
| [Missed-word text blink](#missed-word-text-blink) | `scripts/text_renderer.gd` | End-of-paper review | Highlight alpha on missed planted words |
| [Player progress](#player-progress) | `scripts/player_progress.gd` (autoload) | Onboarding / topic intro complete | `user://progress.cfg` |
| [Shift closure report](#shift-closure-report) | `game2.gd`, `shift_report_content.gd` | Clock `time_out` | Lamp override, paper exit tween, report paper, ending scene |

---

## Shift clock

**Owner:** `clock.gd` (`ShiftClock`, node `%clock_scn`)

| Constant / API | Value / behavior |
|----------------|------------------|
| Shift length | 180 s (`game_timer.wait_time`) |
| `start_shift()` | Resets timer, starts countdown, syncs progress bar |
| `add_time(seconds)` | Extends running timer (used by cofefe sip) |
| `time_out` signal | Emitted when timer hits zero → `game2._on_time_out` → ending scene |
| Visuals | Progress bar fill; `%RekaZegarek` rotates one full turn over the shift; animation speed ×2 in last 25% |

**Consumers:** `flicker_light.gd` reads `time_left` every frame to pick light mode.

---

## Difficulty phases

**Owner:** `game2.gd` — see [`GAME_LOOP.md`](../GAME_LOOP.md) § Difficulty phases.

Phase boundaries: `PHASE_TEACHING_END_S = 60`, `PHASE_LIGHT_END_S = 120`. Same enum names as gameplay phase (`TEACHING`, `LIGHT`, `FULL`) but distinct from light-flicker “tension” mode (naming collision — phases = word obfuscation, flicker = desk lamp).

---

## Onboarding

**Owners:** `game2.gd`, `scripts/onboarding_content.gd`, `scripts/player_progress.gd`

First-time players skip the normal shift until tutorial steps complete. Returning players (`PlayerProgress.has_completed_onboarding()`) jump to `SHIFT_START` briefing only.

### Step machine (`OnboardingStep`)

```
WELCOME → TOILET_LESSON → START_BRIEFING → (mark complete) → topic intro / normal shift
```

Returning player path:

```
SHIFT_START → topic intro / normal shift
```

| Step | Handle | Cofefe | Rubber | Advance when |
|------|--------|--------|--------|--------------|
| `WELCOME` | hidden | hidden | visible | All `WELCOME_TARGETS` marked on scripted paper |
| `TOILET_LESSON` | visible (attract idle) | hidden | hidden | Substep 1+ and toilet targets covered |
| `START_BRIEFING` | visible | hidden | visible | All `BRIEFING_TARGETS` marked → `PlayerProgress.mark_onboarding_complete()` |
| `SHIFT_START` | visible | visible | hidden | Shift-start targets marked |
| `DONE` | normal gameplay | normal | hidden | — |

Scripted copy and target word lists live in `OnboardingContent`. Each step spawns a scene from `DocumentScenes.onboarding()` (under `scenes/documents/`). Progress checked on stroke finish via `_onboarding_check_progress()`. Target words stay **visible** on onboarding and topic-intro papers (optional `hide_target_words` on session if a scene needs invisible targets).

**Debug:** Page Down resets onboarding and reloads the scene (`PlayerProgress.reset_onboarding()`).

---

## Topic intro newspaper

**Owners:** `scripts/topic_content.gd`, `scripts/document_scenes.gd`, `game2.gd`, `paper.gd`

Before the first normal shift for each `WordManager.active_topic_id`, a **desk paper** scene (`DocumentScenes.topic()`) shows topic copy. Shown from `_begin_topic_shift()` when `PlayerProgress.has_seen_topic_intro()` is false.

- Copy and `targets` / `post_it_hint` in `TopicContent.TOPICS`; body built via `TopicContent.build_document_text()`
- Advance: redact all `targets` (transparent until marked) → `mark_topic_intro_seen()` → `_start_normal_shift()`
- Legacy overlay `scenes/topic_newspaper.tscn` is unused; customize `scenes/newspapers/topic_*.tscn` instead

---

## Custom document scenes

**Owners:** `paper.tscn` (base), `scenes/documents/*.tscn`, `scenes/newspapers/*.tscn`, `scripts/document_scenes.gd`

Inherit from `paper.tscn` to author per-step layout in the editor:

| Node | Customize |
|------|-----------|
| `BackgroundGroup/BackgroundPaper` | Swap texture (background art) |
| `TextRenderer` | Position/size of markable text area |
| `Posit` | Post-it sprite position/rotation |
| `%PostItHint` | Label rect and typography on post-it (hint text set from code) |

Register new scenes in `DocumentScenes.ONBOARDING` or `DocumentScenes.TOPIC`. Gameplay spawn: `_spawn_scripted_paper(session, animate, scene)`.

---

## Point light flicker

**Owner:** `scripts/flicker_light.gd` (extends `PointLight2D`, node `%PointLight2D`)

Drives end-of-shift tension: desk lamp flickers, then goes dark.

### Modes (from `ShiftClock.time_left`)

| Mode | When | Behavior |
|------|------|----------|
| `STEADY` | > 10 s left | Full energy, no flicker |
| `TENSION` | 3 s < time ≤ 10 s | Random burst intervals; each burst = 3–5 rapid off/on blinks |
| `DARK` | ≤ 3 s left | Steady off until shift ends |

### Signals

| Signal | When emitted |
|--------|--------------|
| `flicker_off` | Lamp turns off (burst step or steady dark) |
| `flicker_on` | Lamp turns back on |

**Tuning exports:** `tension_interval_min/max`, `flicker_blinks_min/max`, on/off dwell times.

**Consumers:** `game2.gd` `_connect_point_light()` → updates `_point_light_lit` and refreshes desk shadows.

---

## Desk shadows

**Owner:** `game2.gd` — helpers `_fade_cien`, `_refresh_kawa_cien`, `_refresh_popielniczka_cien`

Shadow sprites are separate `Sprite2D` nodes under `CanvasLayer_strokes/CanvasGroup`, faded via `modulate.a` (not hidden), duration `KAWA_CIEN_FADE_DURATION` (0.15 s) unless instant (`duration = 0` on flicker).

| Node | `%` unique name | Visible when | Alpha rule |
|------|-----------------|--------------|------------|
| Coffee shadow | `KawaCien` | Cofefe mug visible | `_point_light_lit && ! _cofefe_dragging` |
| Ashtray shadow | `PopielniczkaCien` | Always (scene default) | `_point_light_lit` |
| Cigarette shadow | `Papieros/PapierosCien` | Papieros visible | `_point_light_lit` |

**Add a new shadow:** give the sprite `unique_name_in_owner`, call `_fade_cien("YourCien", alpha)` from the appropriate refresh handler, hook flicker handlers if it should follow the lamp.

---

## Cofefe mug

**Owner:** `scenes/desk_props/cofefe.gd` (instance `%Cofefe`)

| Input | Signal | Effect in `game2.gd` |
|-------|--------|----------------------|
| Short click (< 10 px move) | `sip_requested` | `consume_sip()` (max 1); `0/1` popup over mug; `+10s` popup over `%clock_scn`; `%CoffeeSipFlash` screen brighten ~1s; `game2._twitch_force += 1`; `Inside` empties |
| Drag | `drag_started` / `drag_ended` | Hides coffee shadow; locks marker during drag (gameplay only) |
| Drag release (moved) | `mug_placed(center, radius, drop_vector, speed)` | If over paper → `marker_layer.apply_mug_smear()` |

Mug raises z-order while dragging and tweens home on release.

---

## Papieros cigarette

**Owner:** `scenes/desk_props/papieros.gd` (instance `%Papieros`)

| State | Click | Visual |
|-------|-------|--------|
| Unlit | First (only) click → place + `puff_requested` (−1 force) | On desk; then tweens to ashtray |
| Burning | No further clicks (`MAX_PUFFS` 1) | Region shrinks ~6 s (fuse); smoke at tip |
| Stub | Ignored | Stays on ashtray; no more calm clicks |

Lit placement: `%popielniczka.position + ASHTRAY_OFFSET_FROM_POP` (from `Papieros_used`), with pivot fix for left-anchored body; each puff after the first nudges ±`ROTATION_PER_PUFF` (~0.11 rad), alternating left/right from base `3.8013272`.

**Twitch force (`game2._twitch_force`):** Coffee +1 on the single sip. Cigarette −1 once on first puff (min 0). Jitters while force &gt; 0; rate/strength scale with force.

**Fuse:** ~6 s burn after the one puff; stub ends use. Coffee force unchanged after stub.

**Marker coupling:** During a twitch, `game2._sync_marker_jitter_to_hand()` sets `draw_position_offset` on the active paper’s `MarkerLayer` so ink follows the displaced hand, including points injected each frame while `drawing`.

**Reset:** `_reset_coffee_cigarette_for_shift()` on each normal shift start (twitch force 0, fresh cigarette).

---

## Toilet handle attract

**Owner:** `game2.gd`

When the toilet handle is visible and the player is idle for `ATTRACT_IDLE_DELAY` (4 s), `_start_handle_attract()` runs a looping sway (`±ATTRACT_SWAY_RAD`) and a brief modulate flash. Any input via `_register_player_activity()` stops attract and settles rotation.

Used during toilet lesson onboarding after the handle appears.

---

## Rubber fly marker

**Owner:** `%Rubber` scene + hooks in `game2.gd`

Rubber eraser prop visible during early onboarding (`WELCOME`, `START_BRIEFING`). Hidden during normal shift. `_notify_fly_marker_idle()` called after each stroke finish to drive fly-to-marker animation when implemented on the Rubber node.

---

## Marker review blink

**Owner:** `scripts/marker_layer.gd`

When review stroke colors are applied (`apply_stroke_colors`), wrong/right tick overlays blink: 3 pulses, half-period 0.33 s, alpha lerps between full and `BLINK_FADE` (0.3). Cleared by `clear_review()`.

---

## Missed-word text blink

**Owner:** `scripts/text_renderer.gd`

Separate from marker review: at end-of-paper review, missed planted words get a highlight whose alpha blinks (3 pulses, `BLINK_FADE` 0.35). Used for “you forgot to mark this” feedback on the memo text itself.

---

## Player progress

**Owner:** `scripts/player_progress.gd` (autoload `PlayerProgress`)

Persisted at `user://progress.cfg`:

| Key | Meaning |
|-----|---------|
| `onboarding_complete` | Skip full tutorial chain |
| `topics_intro_seen` | Dict of `topic_id → bool` for newspaper intro |

API: `has_completed_onboarding()`, `mark_onboarding_complete()`, `has_seen_topic_intro()`, `mark_topic_intro_seen()`, `reset_onboarding()`.

---

## Shift closure report

**Owners:** `game2.gd`, `scripts/shift_report_content.gd`, `scripts/flicker_light.gd`

After the shift clock hits zero, gameplay stays on the desk for a short closure beat before `ending.tscn`.

### Sequence

| Step | Behavior |
|------|----------|
| Clock `time_out` | Save session, stamp check, `_begin_shift_closure()` |
| Dark hold | `flicker_light.force_lamp(false)` — prevents auto relight when timer stops |
| Paper exit | Active memo tweens off (`_tween_paper_out`); handle / mug / cigarette hidden |
| Report in | Lamp `force_lamp(true)`; scripted paper from briefcase with stats + **accept** target |
| Proceed | Player redacts **accept** (same coverage rules as onboarding) → `_end_shift()` → outro videos |

### Report copy

Built by `ShiftReportContent.report_text(score, memos_processed, stamps)` — shift score, memo count (`_paper_index`), stamp count (`_shift_stamps`), compliance disposition.

### Lamp override API (`flicker_light.gd`)

| Method | Effect |
|--------|--------|
| `force_lamp(on: bool)` | Pin lamp on/off; ignores clock-driven modes |
| `release_lamp_override()` | Restore auto flicker (called on next shift start) |

**Consumers:** Desk shadows via existing `flicker_on` / `flicker_off` signals.

---

## Related docs

| Doc | Scope |
|-----|-------|
| [`GAME_LOOP.md`](../GAME_LOOP.md) | Shift loop, scoring, phases, code map |
| [`docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`](../docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md) | At-mark scoring spec |
| [`docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md`](../docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md) | Canonical / typo / synonym model |
