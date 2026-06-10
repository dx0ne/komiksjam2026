# Feature index

Living catalog of gameplay and desk-atmosphere systems. For the core shift loop, scoring, and difficulty phases see [`GAME_LOOP.md`](../GAME_LOOP.md). For original feature specs see [`docs/superpowers/specs/`](../docs/superpowers/specs/).

Maintenance rules for this file: [`AGENTS.md`](../AGENTS.md) § Feature index.

---

## Quick index

| Feature | Owner | Triggers | Affects |
|---------|-------|----------|---------|
| [Shift clock](#shift-clock) | `scenes/gameplay/clock.gd` | `start_shift()`, timer tick | Progress bar, clock hand, light flicker mode |
| [Difficulty phases](#difficulty-phases) | `scenes/flow/game2.gd` | Elapsed shift time | Paper variants, toilet intel, decoys |
| [Onboarding](#onboarding) | `game2.gd`, `scripts/papers/onboarding_content.gd`, `scripts/papers/document_scenes.gd` | First launch | UI visibility, scripted papers, progress save |
| [Topic intro newspaper](#topic-intro-newspaper) | `document_scenes.gd`, `topic_content.gd`, `paper.gd` | First shift per topic | Mark targets on desk paper; blocks shift until redacted |
| [Custom document scenes](#custom-document-scenes) | `scenes/papers/` | Scripted spawn | Background, text area, post-it layout per scene |
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
| [Game audio](#game-audio) | `scripts/audio_manager.gd` (autoload), owners below | Marker draw, props, scoring, lamp, scene flow | `AudioStreamPlayer` on `Master` / `Music` / `Ambient` / `SFX` buses |

---

## Shift clock

**Owner:** `scenes/gameplay/clock.gd` (`ShiftClock`, node `%clock_scn`)

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

**Owners:** `scenes/flow/game2.gd`, `scripts/papers/onboarding_content.gd`, `scripts/player_progress.gd`

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
| `TOILET_LESSON` | visible (attract idle) | hidden | hidden | Substep 0: post-it `pull`, toilet intel `pull` / `the` / `chain`. Substep 1: after pull → UFO / Area 51 intel + redact |
| `START_BRIEFING` | visible | hidden | visible | All `BRIEFING_TARGETS` marked → `PlayerProgress.mark_onboarding_complete()` |
| `SHIFT_START` | visible | visible | hidden | Shift-start targets marked |
| `DONE` | normal gameplay | normal | hidden | — |

Scripted copy and target word lists live in `OnboardingContent` (`scripts/papers/onboarding_content.gd`). Each step spawns a scene from `DocumentScenes.onboarding()` (under `scenes/papers/`). Progress checked on stroke finish via `_onboarding_check_progress()`. Target words stay **visible** on onboarding and topic-intro papers (optional `hide_target_words` on session if a scene needs invisible targets).

**Debug:** Page Down resets onboarding and reloads the scene (`PlayerProgress.reset_onboarding()`).

---

## Topic intro newspaper

**Owners:** `scripts/papers/topic_content.gd`, `scripts/papers/document_scenes.gd`, `scenes/flow/game2.gd`, `scenes/gameplay/paper.gd`

Before the first normal shift for each `WordManager.active_topic_id`, a **desk paper** scene (`DocumentScenes.topic()`) shows topic copy. Shown from `_begin_topic_shift()` when `PlayerProgress.has_seen_topic_intro()` is false.

- Copy and `targets` / `post_it_hint` in `TopicContent.TOPICS`; body built via `TopicContent.build_document_text()`
- Advance: redact all `targets` (transparent until marked) → `mark_topic_intro_seen()` → `_start_normal_shift()`
- Customize layout per topic in `scenes/papers/topic_*.tscn`

---

## Custom document scenes

**Owners:** `scenes/gameplay/paper.tscn` (base), `scenes/papers/*.tscn`, `scripts/papers/document_scenes.gd`

Inherit from `scenes/gameplay/paper.tscn` to author per-step layout in the editor:

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
| `TENSION` | 0 < time ≤ 10 s | 1 Hz countdown: toggles on/off each whole second (even seconds on, odd off); off at 0 |

### Signals

| Signal | When emitted |
|--------|--------------|
| `flicker_off` | Lamp turns off (burst step or steady dark) |
| `flicker_on` | Lamp turns back on |

**Sync:** `_sync_countdown_lamp()` reads `floor(time_left)` each frame; emits `flicker_on` / `flicker_off` on second boundaries only.

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

**Owners:** `scenes/flow/game2.gd`, `scripts/papers/shift_report_content.gd`, `scripts/flicker_light.gd`

After the shift clock hits zero, gameplay stays on the desk for a short closure beat before `ending.tscn`.

### Sequence

| Step | Behavior |
|------|----------|
| Clock `time_out` | Save session, stamp check, `_begin_shift_closure()` |
| Desk clear | Lamp off + `lamp_final_off` + `shift_report_arrive` SFX; handle / mug / cigarette / toilet intel and active memo tween off together (**0.45 s**, `SHIFT_CLOSURE_UI_EXIT_DURATION_S`) |
| Report in | Lamp `force_lamp(true)` + `lamp_relight`; shift report slides in from briefcase (`memo_spawn` SFX) with stats + **accept** target |
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

## Game audio

**Status:** Wired — assets under `audio/`, `AudioManager` autoload, buses in `default_bus_layout.tres`.

**Owner:** `scripts/audio_manager.gd` (autoload) — one-shot pool and ambient/music loops.

| Bus | Use |
|-----|-----|
| `Master` | Final mix (0 dB) |
| `Music` | Menu ambient |
| `Ambient` | Shift ambient (onboarding + normal shift) |
| `SFX` | One-shots and procedural marker friction |

**Scene owners:** `scripts/marker_friction_noise.gd` + `scripts/marker_layer.gd` (marker friction + mug smear), `scenes/desk_props/rubber.gd` (fly click erase), `scenes/flow/game2.gd` (shift orchestration), `scenes/flow/main_menu.gd` (menu ambient + redaction confirms), scene-local prop scripts (`cofefe.gd`, `papieros.gd`), `scenes/gameplay/paper.gd` (stamp). Lamp flicker clicks wired in `game2.gd` off `flicker_light.gd` signals.

### Global rules

| Rule | Detail |
|------|--------|
| **Video keeps its audio** | Intro, ending, and outro `.ogv` clips (`video/`) ship with embedded sound. Do not replace or mute unless adding a global duck slider later. |
| **No audio over video scenes** | `intro_scene.tscn`, `ending.tscn`, `outro.tscn` — no separate music/SFX layer unless explicitly mixed under video. |
| **Buses** | Plan at least `Master`, `Music`, `Ambient`, `SFX`. Unmute and tune when first assets land. Settings UI (`options__settings.gd`) has no volume controls yet. |

### Marker friction (procedural noise)

**Owner:** `scripts/marker_friction_noise.gd` (child of `MarkerLayer`)

No looped Foley asset. While `drawing == true`, cursor speed maps to **low-pass white noise** amplitude (quieter when slow, silent when still). `DrawMode.LINE` uses a slightly lower bus level than `DrawMode.BRUSH`.

| Constant | Value | Meaning |
|----------|-------|---------|
| `MIN_SPEED_PX_S` | `30` | Below this → silence |
| `MAX_SPEED_PX_S` | `900` | Full noise level |
| `BASE_VOLUME_DB` | `-14` | Overall subtlety |
| `LINE_MODE_DB_OFFSET` | `-5` | Line mode quieter than brush |

**Algorithm:**

1. While `drawing == false` → target level 0 (smooth fade via lerp).
2. Each frame while drawing → `speed = distance / delta` from stroke point; map to `[0, 1]` and square for soft onset.
3. `AudioStreamGenerator` fills frames with filtered noise scaled by current level.
4. On stroke finish → stop friction only (no release one-shot).

**Also marker-owned (one-shots):**

| Trigger | Sound |
|---------|-------|
| `apply_mug_smear()` | `mug_smear` |

**Consumers:** Main menu uses the same `MarkerLayer` for PLAY / SAVE redaction (`main_menu.gd`) — shares friction noise.

### Rubber fly (click only)

**Owner:** `scenes/desk_props/rubber.gd`

Silent during entrance, walk, flee, and return. One SFX on player click that triggers `erase_requested`:

| Trigger | Sound |
|---------|-------|
| Click + `erase_requested` | `fly_erase_click` |

Visible only during onboarding steps (`WELCOME`, `START_BRIEFING`); hidden in normal shift.

### Sound asset checklist

Assets live under `audio/music/` and `audio/sfx/` (MP3). IDs map to `AudioManager` keys.

#### Music & ambient

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| A1 | `shift_ambient_loop` | Onboarding + normal shift | `game2.gd` |
| A2 | `menu_ambient_loop` | `main_menu.tscn` | `main_menu.gd` |

#### Core gameplay

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| G1 | Marker friction (procedural) | Cursor speed while drawing | `marker_friction_noise.gd` |
| G2 | Wrong-mark accent | Red stroke in `_color_stroke_by_deltas` | `game2.gd` |
| G3 | Mug smear | `apply_mug_smear()` | `marker_layer.gd` |
| G4 | Stamp slam | `paper.set_stamp_visible(true)` | `paper.gd` |

#### Paper & toilet

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| P1 | `memo_spawn` | `_prepare_paper_spawn(animate_in: true)` | `game2.gd` |
| P2 | `shift_report_arrive` | Shift closure — props slide off | `game2.gd` |
| T1 | `toilet_handle_pull` | `toilet_pull()` | `game2.gd` |
| T2 | `intel_strip_spawn` | `_spawn_toilet_intel_messages()` | `game2.gd` |
| T3 | `handle_attract_creak` | `_start_handle_attract()` | `game2.gd` |

#### Desk props

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| D1 | `coffee_sip` | `consume_sip()` | `cofefe.gd` |
| D2 | `clock_time_ping` | `_spawn_clock_time_popup()` | `game2.gd` |
| D3 | `mug_set_down` | Mug home tween end | `cofefe.gd` |
| D4 | `cigarette_puff` | `puff_requested` | `papieros.gd` |
| D5 | `cigarette_on_ashtray` | `_place_on_ashtray()` | `papieros.gd` |
| D6 | `hand_twitch` | `_twitch_right_hand()` | `game2.gd` |
| D7 | `fly_erase_click` | Click erase on rubber | `rubber.gd` |

#### Lamp & menu

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| L1 | `lamp_flicker_click` | `flicker_off` / `flicker_on` (last 10 s) | `game2.gd` |
| L2 | `lamp_final_off` | `_begin_shift_closure()` | `game2.gd` |
| L3 | `lamp_relight` | `force_lamp(true)` at closure | `game2.gd` |
| M1 | `menu_play_confirmed` | PLAY redacted on menu | `main_menu.gd` |
| M2 | `menu_save_wipe` | SAVE redacted | `main_menu.gd` |

**Cut from scope:** separate tension/onboarding music tracks, dark-hold stinger, score pop SFX, memo land/discard, intel strip land, cigarette stub, fly state transition one-shots, stroke release, end-of-paper review blinks (review UI not wired in `game2.gd`).

### Video audio (no separate assets)

| File | Scene |
|------|-------|
| `video/intro-do-gry-mp4.ogv` | `intro_scene.tscn` |
| `video/Speaker-intro_1.ogv` | `ending.tscn` (intro roll) |
| `video/outro-redacted-proper_1.ogv` | `ending.tscn` (good) |
| `video/outro-aliens_1.ogv` | `ending.tscn` (bad) |
| `video/newspaper.ogv` | `outro.tscn` |

### When to update this section

Update in the **same change** when:

- Adding `AudioStreamPlayer` nodes or an audio autoload
- Connecting a new signal → SFX hook (mirror [feature index rules](../AGENTS.md))
- Changing marker sampling rules or fly state machine
- Adding volume / mute settings

---

## Related docs

| Doc | Scope |
|-----|-------|
| [`GAME_LOOP.md`](../GAME_LOOP.md) | Shift loop, scoring, phases, code map |
| [`docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`](../docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md) | At-mark scoring spec |
| [`docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md`](../docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md) | Canonical / typo / synonym model |
