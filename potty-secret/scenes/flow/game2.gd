extends Node2D

const REDACTION_TOLERANCE  := 12.0
const SAMPLE_STEP          := 6.0
const COVERAGE_CELL_WIDTH  := 8.0
const COVERAGE_HALF_RATIO  := 0.50
const COVERAGE_FULL_RATIO  := 0.70
const COVERAGE_MIN_CELLS   := 2
const TOILET_INTEL_COUNT   := 3
const WORDS_IN_DOCUMENT    := 3

enum Phase { TEACHING, LIGHT, FULL }
enum OnboardingStep { WELCOME, TOILET_LESSON, START_BRIEFING, SHIFT_START, DONE }
const PHASE_TEACHING_END_S := 60.0
const PHASE_LIGHT_END_S    := 120.0
const LEFT_HAND_OFFSCREEN_Y := 400.0

const TOILET_SCN       := preload("res://scenes/gameplay/toilet_msg.tscn")
const PAPER_SCN        := preload("res://scenes/gameplay/paper.tscn")
const ScorePopupScene  := preload("res://scenes/gameplay/score_popup.tscn")

const ATTRACT_IDLE_DELAY := 4.0
const ATTRACT_SWAY_RAD   := 0.035
const KAWA_CIEN_FADE_DURATION := 0.15

const COFFEE_SIPS_PER_SHIFT := 1
const COFFEE_TIME_BONUS_S := 10.0
const COFFEE_TIME_POPUP_OFFSET := Vector2(24.0, -72.0)
const COFFEE_JITTER_MIN_S := 7.0 / 3.0
const COFFEE_JITTER_MAX_S := 16.0 / 3.0
const SHIFT_CLOSURE_UI_EXIT_DURATION_S := 0.45
const HANDLE_EXIT_OFFSET := Vector2(-520.0, 0.0)
const COFEFE_EXIT_OFFSET := Vector2(-200.0, -240.0)
const PAPIEROS_EXIT_OFFSET := Vector2(160.0, -220.0)
const TOILET_INTEL_EXIT_OFFSET := Vector2(-420.0, -80.0)
## Just above flicker_light.gd TENSION_START_S — lamp steady, flicker on next tick down.
const DEBUG_JUMP_TIME_LEFT_S := 10.01
## Temporary: skip topic intro newspaper after onboarding / shift start.
const SKIP_TOPIC_INTRO := true
## Higher force → shorter wait between twitches (see `_jitter_interval_for_force`).
const TWITCH_FORCE_INTERVAL_STEP := 0.38
const HAND_TWITCH_OFFSET := Vector2(22.0, -14.0)
const HAND_TWITCH_ROT := 0.07
## Radians from straight up/down; keeps twitches mostly vertical, not left/right.
const TWITCH_VERTICAL_SPREAD := 0.5
const TWITCH_FORCE_OFFSET_STEP := 0.14
const HAND_TWITCH_OUT_S := 0.07
const HAND_TWITCH_RETURN_S := 0.32

@onready var clock: ShiftClock = %clock_scn
@onready var _palec_animation: AnimationPlayer = %Palec2

var viewport_size: Vector2
var rng := RandomNumberGenerator.new()

var active_paper: GamePaper = null
var session: Dictionary = {}

var _idle_time: float = 0.0
var _attract_tween: Tween = null
var _cien_tweens: Dictionary = {}
var _cofefe_dragging := false
var _point_light_lit := true
var _twitch_force := 0
var _coffee_jitter_timer: Timer
var _hand_twitch_tween: Tween
var _hand_jitter_active := false
var _paper_index: int = 0
var _shift_stamps: int = 0
var _shift_ending := false
var _outgoing_paper: GamePaper = null
var _onboarding_step: OnboardingStep = OnboardingStep.DONE
var _onboarding_substep: int = 0
var _topic_intro_active: bool = false
var _left_hand_rest_pos: Vector2 = Vector2.ZERO
var _cofefe_rest_pos: Vector2 = Vector2.ZERO
var _kawa_cien_rest_pos: Vector2 = Vector2.ZERO
var _papieros_rest_pos: Vector2 = Vector2.ZERO
var _shift_closure_ui_tween: Tween


func _text_renderer() -> TextRenderer:
	return active_paper.text_renderer if active_paper else null


func _marker_layer() -> MarkerLayer:
	return active_paper.marker_layer if active_paper else null


func _debug_overlay() -> DebugOverlay:
	return active_paper.debug_overlay if active_paper else null


func _ready() -> void:
	rng.randomize()
	viewport_size = get_viewport().get_visible_rect().size
	_cofefe_rest_pos = %Cofefe.position
	_kawa_cien_rest_pos = %KawaCien.position
	_papieros_rest_pos = %Papieros.position

	%gimme_toilet_btn.gui_input.connect(_on_gimme_toilet_btn_gui_input)
	clock.time_out.connect(_on_time_out)
	_connect_cofefe()
	_connect_papieros()
	_connect_rubber()
	_connect_point_light()
	_setup_coffee_jitter_timer()

	WordManager.shift_score = 0.0

	_set_redaction_loop_animations(false)

	if PlayerProgress.has_completed_onboarding():
		_begin_shift_start()
	else:
		_begin_onboarding()


func _process(delta: float) -> void:
	if _hand_jitter_active:
		_sync_marker_jitter_to_hand()
	if _onboarding_step == OnboardingStep.WELCOME \
			or _onboarding_step == OnboardingStep.START_BRIEFING \
			or _onboarding_step == OnboardingStep.SHIFT_START:
		return
	if _shift_ending:
		return
	if _onboarding_step == OnboardingStep.TOILET_LESSON and _onboarding_substep != 0:
		return
	if _attract_tween != null:
		return
	_idle_time += delta
	if _idle_time >= ATTRACT_IDLE_DELAY:
		_start_handle_attract()


func _input(event: InputEvent) -> void:
	_register_player_activity()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_PAGEDOWN:
		PlayerProgress.reset_onboarding()
		get_tree().reload_current_scene()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_PAGEUP:
		if _onboarding_step == OnboardingStep.DONE and not _shift_ending:
			clock.set_time_left(DEBUG_JUMP_TIME_LEFT_S)
		return
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("rand_toilet_msg") or event.is_action_pressed("rand_document"):
		toilet_pull()
	if event.is_action_pressed("skip_to_ending"):
		_end_shift()


func _unhandled_input(event: InputEvent) -> void:
	if active_paper == null:
		return
	var marker_layer := _marker_layer()
	var debug_overlay := _debug_overlay()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_D and debug_overlay:
			debug_overlay.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and marker_layer:
			var new_mode := MarkerLayer.DrawMode.BRUSH \
				if marker_layer.mode == MarkerLayer.DrawMode.LINE \
				else MarkerLayer.DrawMode.LINE
			marker_layer.set_mode(new_mode)
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Onboarding
# ---------------------------------------------------------------------------

func _begin_onboarding() -> void:
	_onboarding_step = OnboardingStep.WELCOME
	_onboarding_substep = 0

	var left_hand: Sprite2D = %LeftHand
	_left_hand_rest_pos = left_hand.position
	left_hand.position.y += LEFT_HAND_OFFSCREEN_Y

	_set_toilet_handle_visible(false)
	_clear_toilet_intel()
	_set_rubber_visible(true)
	_set_papieros_visible(false)

	WordManager.current_toilet_canonicals = []
	WordManager.current_toilet_words = []

	_spawn_scripted_paper(
		_build_tutorial_session(
			OnboardingContent.WELCOME_TEXT,
			OnboardingContent.WELCOME_TARGETS
		),
		true,
		DocumentScenes.onboarding("welcome")
	)
	if active_paper:
		active_paper.set_onboarding_ui(true)
	AudioManager.play_shift_ambient()


func _begin_shift_start() -> void:
	_onboarding_step = OnboardingStep.SHIFT_START
	_onboarding_substep = 0
	WordManager.shift_score = 0.0
	_set_toilet_handle_visible(true)
	_set_cofefe_visible(true)
	_set_papieros_visible(false)
	_set_rubber_visible(false)
	_spawn_scripted_paper(
		_build_tutorial_session(
			OnboardingContent.shift_start_text(),
			OnboardingContent.SHIFT_START_TARGETS
		),
		true,
		DocumentScenes.onboarding("shift_start")
	)
	if active_paper:
		active_paper.set_onboarding_ui(true)
	_show_scripted_intel(OnboardingContent.SHIFT_START_TARGETS)
	AudioManager.play_shift_ambient()


func _begin_topic_shift() -> void:
	if SKIP_TOPIC_INTRO or PlayerProgress.has_seen_topic_intro(WordManager.active_topic_id):
		_start_normal_shift(true)
		return
	_start_topic_intro_document()


func _start_topic_intro_document() -> void:
	_topic_intro_active = true
	_onboarding_step = OnboardingStep.DONE
	_clear_outgoing_paper()
	_set_toilet_handle_visible(false)
	_clear_toilet_intel()
	_set_rubber_visible(false)

	var topic_id := WordManager.active_topic_id
	var data := TopicContent.get_topic(topic_id)
	var targets := TopicContent.targets_from_data(data)
	var intro_session := _build_tutorial_session(
		TopicContent.build_document_text(data),
		targets
	)
	intro_session["show_letterhead"] = false
	_spawn_scripted_paper(intro_session, true, DocumentScenes.topic(topic_id))
	if active_paper:
		active_paper.set_onboarding_ui(true)


func _tutorial_targets_from_session() -> Array[String]:
	var raw: Array = session.get("tutorial_targets", [])
	if raw.is_empty():
		raw = session.get("planted_canonicals", [])
	var out: Array[String] = []
	for t in raw:
		out.append(str(t))
	return out


func _tutorial_planted_canonicals(targets: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for t in targets:
		var canon := WordManager.canonicalize(t)
		out.append(canon if not canon.is_empty() else WordManager._normalize(t))
	return out


func _topic_intro_check_progress() -> void:
	if not _topic_intro_targets_marked(_tutorial_targets_from_session()):
		return
	_topic_intro_active = false
	PlayerProgress.mark_topic_intro_seen(WordManager.active_topic_id)
	_start_normal_shift(true)


func _start_normal_shift(spawn_paper: bool = true) -> void:
	_topic_intro_active = false
	_onboarding_step = OnboardingStep.DONE
	_onboarding_substep = 0
	_shift_ending = false
	_shift_stamps = 0
	_paper_index = 0
	WordManager.shift_score = 0.0
	_reset_coffee_cigarette_for_shift()
	_release_point_light_override()
	_show_gameplay_ui()
	clock.start_shift()
	_set_redaction_loop_animations(true)
	AudioManager.play_shift_ambient()
	if spawn_paper:
		_spawn_fresh_paper(true)
		_roll_toilet_intel(true)


func _show_gameplay_ui() -> void:
	_reset_shift_closure_ui_positions()
	_set_toilet_handle_visible(true)
	_set_cofefe_visible(true)
	_set_papieros_visible(true)
	_set_rubber_visible(false)
	if active_paper:
		active_paper.set_onboarding_ui(false)


func _set_toilet_handle_visible(show_handle: bool) -> void:
	var handle := %toilet_handle
	handle.visible = show_handle
	%gimme_toilet_btn.disabled = not show_handle


func _set_cofefe_visible(show_mug: bool) -> void:
	var cofefe: Node2D = %Cofefe
	cofefe.visible = show_mug
	var shadow := get_node_or_null("%KawaCien") as CanvasItem
	if shadow == null:
		return
	_kill_cien_tween("KawaCien")
	shadow.visible = show_mug
	if show_mug:
		_refresh_kawa_cien(0.0)


func _refresh_kawa_cien(fade_duration: float = KAWA_CIEN_FADE_DURATION) -> void:
	var show_shadow := _point_light_lit and not _cofefe_dragging
	_fade_cien("KawaCien", 1.0 if show_shadow else 0.0, fade_duration)


func _refresh_popielniczka_cien(fade_duration: float = KAWA_CIEN_FADE_DURATION) -> void:
	_fade_cien("PopielniczkaCien", 1.0 if _point_light_lit else 0.0, fade_duration)


func _refresh_papieros_cien(fade_duration: float = KAWA_CIEN_FADE_DURATION) -> void:
	var papieros: Node2D = %Papieros
	if not papieros.visible:
		return
	var shadow := papieros.get_node_or_null("PapierosCien") as CanvasItem
	if shadow == null:
		return
	var key: StringName = &"PapierosCien"
	var to_alpha := 1.0 if _point_light_lit else 0.0
	_kill_cien_tween(key)
	if fade_duration <= 0.0:
		shadow.modulate.a = to_alpha
		return
	var tween := create_tween()
	_cien_tweens[key] = tween
	tween.tween_property(shadow, "modulate:a", to_alpha, fade_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_papieros_visible(show_cigarette: bool) -> void:
	var papieros: Node2D = %Papieros
	papieros.visible = show_cigarette
	if show_cigarette:
		_refresh_papieros_cien(0.0)


func _kill_cien_tween(unique_name: StringName) -> void:
	if not _cien_tweens.has(unique_name):
		return
	var tween: Tween = _cien_tweens[unique_name]
	if tween and tween.is_valid():
		tween.kill()
	_cien_tweens.erase(unique_name)


func _fade_cien(unique_name: StringName, to_alpha: float, duration: float = KAWA_CIEN_FADE_DURATION) -> void:
	var shadow := get_node_or_null("%" + str(unique_name)) as CanvasItem
	if shadow == null or not shadow.visible:
		return
	_kill_cien_tween(unique_name)
	if duration <= 0.0:
		shadow.modulate.a = to_alpha
		return
	var tween := create_tween()
	_cien_tweens[unique_name] = tween
	tween.tween_property(shadow, "modulate:a", to_alpha, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _kill_shift_closure_ui_tween() -> void:
	if _shift_closure_ui_tween and _shift_closure_ui_tween.is_valid():
		_shift_closure_ui_tween.kill()
	_shift_closure_ui_tween = null


func _reset_shift_closure_ui_positions() -> void:
	_kill_shift_closure_ui_tween()
	var handle := %toilet_handle
	handle.position = Vector2.ZERO
	handle.rotation = 0.0
	handle.modulate = Color.WHITE
	%Cofefe.position = _cofefe_rest_pos
	%KawaCien.position = _kawa_cien_rest_pos
	%Papieros.position = _papieros_rest_pos


func _tween_shift_closure_ui_out(paper_to_exit: GamePaper = null) -> Tween:
	_kill_shift_closure_ui_tween()
	%gimme_toilet_btn.disabled = true

	var tween := create_tween().set_parallel(true)
	_shift_closure_ui_tween = tween

	if paper_to_exit != null:
		_tween_paper_out(
			paper_to_exit,
			SHIFT_CLOSURE_UI_EXIT_DURATION_S,
			tween
		)

	var handle := %toilet_handle
	tween.tween_property(
		handle,
		"position",
		handle.position + HANDLE_EXIT_OFFSET,
		SHIFT_CLOSURE_UI_EXIT_DURATION_S
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	var cofefe: Node2D = %Cofefe
	if cofefe.visible:
		_kill_cien_tween("KawaCien")
		var kawa_cien: Node2D = %KawaCien
		tween.tween_property(
			cofefe,
			"position",
			cofefe.position + COFEFE_EXIT_OFFSET,
			SHIFT_CLOSURE_UI_EXIT_DURATION_S
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(
			kawa_cien,
			"position",
			kawa_cien.position + COFEFE_EXIT_OFFSET,
			SHIFT_CLOSURE_UI_EXIT_DURATION_S
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	var papieros: Node2D = %Papieros
	if papieros.visible:
		_kill_cien_tween(&"PapierosCien")
		tween.tween_property(
			papieros,
			"position",
			papieros.position + PAPIEROS_EXIT_OFFSET,
			SHIFT_CLOSURE_UI_EXIT_DURATION_S
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	for child in %toilet_msgs_container.get_children():
		if not child is ToiletMsg:
			continue
		var msg := child as ToiletMsg
		tween.tween_property(
			msg,
			"position",
			msg.position + TOILET_INTEL_EXIT_OFFSET,
			SHIFT_CLOSURE_UI_EXIT_DURATION_S
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(_hide_shift_closure_ui_after_exit)
	return tween


func _hide_shift_closure_ui_after_exit() -> void:
	_shift_closure_ui_tween = null
	if _outgoing_paper != null and is_instance_valid(_outgoing_paper):
		_outgoing_paper.queue_free()
		_outgoing_paper = null
	_set_toilet_handle_visible(false)
	_set_cofefe_visible(false)
	_set_papieros_visible(false)
	_clear_toilet_intel()
	_reset_shift_closure_ui_positions()


func _set_rubber_visible(show_rubber: bool) -> void:
	var rubber: Node2D = get_node_or_null("%Rubber")
	if rubber == null:
		return
	rubber.visible = show_rubber
	if show_rubber and rubber.has_method("play_entrance"):
		rubber.play_entrance()
	elif not show_rubber and rubber.has_method("reset_fly"):
		rubber.reset_fly()


func _clear_toilet_intel() -> void:
	for child in %toilet_msgs_container.get_children():
		child.queue_free()
	WordManager.current_toilet_canonicals = []
	WordManager.current_toilet_words = []


func _expire_existing_toilet_intel() -> void:
	for child in %toilet_msgs_container.get_children():
		if child is ToiletMsg:
			child.set_expired()


func _build_tutorial_session(text: String, targets: Array[String], decoys: Array = []) -> Dictionary:
	var planted_canonicals := _tutorial_planted_canonicals(targets)
	return {
		"text": text,
		"planted_words": targets.duplicate(),
		"planted_canonicals": planted_canonicals,
		"planted_total": targets.size(),
		"decoys": decoys,
		"word_scores": {} as Dictionary,
		"strokes": [] as Array[PackedVector2Array],
		"stamped": false,
		"phase": int(Phase.TEACHING),
		"tutorial_targets": targets.duplicate(),
		"show_letterhead": true,
	}


func _spawn_scripted_paper(
	scripted_session: Dictionary,
	animate_in: bool,
	paper_scene: PackedScene = PAPER_SCN
) -> void:
	_prepare_paper_spawn(animate_in, paper_scene)
	session = scripted_session
	_load_session()
	if _onboarding_step == OnboardingStep.DONE:
		_refresh_postit_and_penalty()
	_paper_index += 1


func _onboarding_check_progress() -> void:
	if not _tutorial_all_targets_covered(_tutorial_targets_from_session()):
		return

	match _onboarding_step:
		OnboardingStep.WELCOME:
			_advance_to_toilet_lesson()
		OnboardingStep.TOILET_LESSON:
			if _onboarding_substep >= 1:
				_advance_to_start_briefing()
		OnboardingStep.START_BRIEFING:
			PlayerProgress.mark_onboarding_complete()
			_begin_topic_shift()
		OnboardingStep.SHIFT_START:
			_begin_topic_shift()


func _advance_to_toilet_lesson() -> void:
	_onboarding_step = OnboardingStep.TOILET_LESSON
	_onboarding_substep = 0
	_set_toilet_handle_visible(true)
	_idle_time = ATTRACT_IDLE_DELAY
	_clear_toilet_intel()
	var toilet_session := _build_tutorial_session(
		OnboardingContent.toilet_text(),
		OnboardingContent.TOILET_TARGETS
	)
	_spawn_scripted_paper(
		toilet_session,
		true,
		DocumentScenes.onboarding("toilet")
	)
	if active_paper:
		active_paper.set_onboarding_ui(true)
	_spawn_onboarding_pull_hint_intel()
	_start_handle_attract()


func _spawn_onboarding_pull_hint_intel() -> void:
	WordManager.current_toilet_canonicals = []
	WordManager.current_toilet_words = []
	_spawn_toilet_intel_messages(OnboardingContent.TOILET_INTEL_PULL_HINT)


func _advance_to_start_briefing() -> void:
	_onboarding_step = OnboardingStep.START_BRIEFING
	_onboarding_substep = 0
	_set_rubber_visible(true)

	var left_hand: Sprite2D = %LeftHand
	var tween := create_tween()
	tween.tween_property(left_hand, "position", _left_hand_rest_pos, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_spawn_scripted_paper(
		_build_tutorial_session(
			OnboardingContent.briefing_text(),
			OnboardingContent.BRIEFING_TARGETS
		),
		true,
		DocumentScenes.onboarding("briefing")
	)
	if active_paper:
		active_paper.set_onboarding_ui(true)
	_show_scripted_intel(OnboardingContent.BRIEFING_TARGETS)


func _tutorial_stroke_samples_in_text_space() -> Array[PackedVector2Array]:
	var marker_layer := _marker_layer()
	if marker_layer == null:
		return []
	return _stroke_samples_in_text_space_from_array(marker_layer.strokes)


func _topic_intro_targets_marked(targets: Array[String]) -> bool:
	var text_renderer := _text_renderer()
	if text_renderer == null or targets.is_empty():
		return false
	var all_samples := _tutorial_stroke_samples_in_text_space()
	if all_samples.is_empty():
		return false

	var need_count: Dictionary = {}
	for target in targets:
		var key := _tutorial_target_key(target)
		need_count[key] = need_count.get(key, 0) + 1

	var got_count: Dictionary = {}
	for key in need_count:
		got_count[key] = 0

	for box in text_renderer.word_boxes:
		if not _tutorial_box_has_stroke_overlap(box, all_samples):
			continue
		for key in need_count:
			if got_count[key] >= need_count[key]:
				continue
			if _tutorial_word_matches(box, key):
				got_count[key] += 1
				break

	for key in need_count:
		if got_count[key] < need_count[key]:
			return false
	return true


func _tutorial_box_has_stroke_overlap(box: Dictionary, all_samples: Array[PackedVector2Array]) -> bool:
	var grown: Rect2 = box["rect"].grow(REDACTION_TOLERANCE)
	for samples in all_samples:
		for point in samples:
			if grown.has_point(point):
				return true
	return false


func _tutorial_all_targets_covered(targets: Array[String]) -> bool:
	var text_renderer := _text_renderer()
	if text_renderer == null or targets.is_empty():
		return false
	var all_samples := _tutorial_stroke_samples_in_text_space()
	if all_samples.is_empty():
		return false

	var need_count: Dictionary = {}
	for target in targets:
		var key := _tutorial_target_key(target)
		need_count[key] = need_count.get(key, 0) + 1

	var got_count: Dictionary = {}
	for key in need_count:
		got_count[key] = 0

	for box in text_renderer.word_boxes:
		var tier := _word_coverage_tier_from_strokes(box, all_samples)
		if tier != "half" and tier != "full":
			continue
		for key in need_count:
			if got_count[key] >= need_count[key]:
				continue
			if _tutorial_word_matches(box, key):
				got_count[key] += 1
				break

	for key in need_count:
		if got_count[key] < need_count[key]:
			return false
	return true


func _tutorial_target_key(target: String) -> String:
	var canon := WordManager.canonicalize(target)
	if not canon.is_empty():
		return canon
	return WordManager._normalize(target)


func _tutorial_word_matches(box: Dictionary, target_key: String) -> bool:
	var box_word: String = box.get("word", "")
	if box_word == target_key:
		return true
	var canon := WordManager.canonicalize(box.get("display", ""))
	if not canon.is_empty():
		return canon == target_key or WordManager._normalize(canon) == target_key
	var display_norm := WordManager._normalize(str(box.get("display", "")))
	return display_norm == target_key


func _show_scripted_intel(display_words: Array[String]) -> void:
	_clear_toilet_intel()
	var canonicals: Array[String] = session.get("planted_canonicals", [])
	WordManager.current_toilet_canonicals = canonicals.duplicate()
	WordManager.current_toilet_words = display_words.duplicate()
	_spawn_toilet_intel_messages(display_words)
	if session.has("text"):
		_apply_toilet_to_current_paper()


func _onboarding_toilet_pull() -> void:
	var original_pos := Vector2.ZERO
	var offset_pos := original_pos + Vector2(0, 100)
	var trans_time := 0.2

	var tween := create_tween()
	tween.tween_property(%toilet_handle, "position", offset_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(%toilet_handle, "position", original_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_onboarding_after_toilet_pull)


func _onboarding_after_toilet_pull() -> void:
	if _onboarding_step != OnboardingStep.TOILET_LESSON or _onboarding_substep != 0:
		return
	_onboarding_substep = 1
	_stop_handle_attract()
	_show_scripted_intel(OnboardingContent.TOILET_TARGETS)
	if active_paper:
		active_paper.set_onboarding_ui(true, " · ".join(OnboardingContent.TOILET_TARGETS))


func _on_rubber_erase() -> void:
	var marker_layer := _marker_layer()
	if marker_layer == null:
		return
	marker_layer.clear_strokes()
	session["strokes"] = []
	session["word_scores"] = {}


func _on_marker_drawing_started() -> void:
	var rubber: Node2D = get_node_or_null("%Rubber")
	if rubber and rubber.has_method("notify_marker_drawing"):
		rubber.notify_marker_drawing(true)


func _notify_fly_marker_idle() -> void:
	var rubber: Node2D = get_node_or_null("%Rubber")
	if rubber and rubber.has_method("notify_marker_drawing"):
		rubber.notify_marker_drawing(false)


func _connect_rubber() -> void:
	var rubber: Node2D = get_node_or_null("%Rubber")
	if rubber == null:
		return
	if rubber.has_signal("erase_requested"):
		rubber.erase_requested.connect(_on_rubber_erase)


# ---------------------------------------------------------------------------
# Paper lifecycle
# ---------------------------------------------------------------------------

const PAPER_EXIT_DURATION_S := 0.35
const PAPER_EXIT_ROT_RANGE_DEG := 14.0


func _disconnect_paper_signals(paper: GamePaper) -> void:
	if paper.marker_layer.stroke_finished.is_connected(_on_stroke_finished):
		paper.marker_layer.stroke_finished.disconnect(_on_stroke_finished)
	if paper.marker_layer.stroke_started.is_connected(_on_marker_drawing_started):
		paper.marker_layer.stroke_started.disconnect(_on_marker_drawing_started)


func _clear_outgoing_paper() -> void:
	if _outgoing_paper != null and is_instance_valid(_outgoing_paper):
		_outgoing_paper.queue_free()
	_outgoing_paper = null


func _tween_paper_out(
	paper: GamePaper,
	duration_s: float = PAPER_EXIT_DURATION_S,
	parent_tween: Tween = null
) -> void:
	_clear_outgoing_paper()
	_outgoing_paper = paper
	paper.marker_layer.set_locked(true)
	paper.stabilize_stamp_for_exit()
	paper.prepare_for_exit()
	%papers_container.move_child(paper, 0)

	var exit_pos := paper.position + Vector2(
		rng.randf_range(-120.0, -40.0),
		rng.randf_range(-280.0, -160.0)
	)
	var exit_rot := paper.rotation + deg_to_rad(
		rng.randf_range(-PAPER_EXIT_ROT_RANGE_DEG, PAPER_EXIT_ROT_RANGE_DEG)
	)

	var free_paper := func() -> void:
		if _outgoing_paper == paper and is_instance_valid(paper):
			paper.queue_free()
			_outgoing_paper = null

	if parent_tween != null:
		parent_tween.tween_property(paper, "position", exit_pos, duration_s) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		parent_tween.tween_property(paper, "rotation", exit_rot, duration_s) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		return

	var tween := paper.create_tween().set_parallel(true)
	tween.tween_property(paper, "position", exit_pos, duration_s) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(paper, "rotation", exit_rot, duration_s) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(free_paper)


func _prepare_paper_spawn(animate_in: bool, paper_scene: PackedScene = PAPER_SCN) -> void:
	if active_paper:
		_disconnect_paper_signals(active_paper)
		_tween_paper_out(active_paper)
		active_paper = null

	active_paper = paper_scene.instantiate() as GamePaper
	active_paper.z_index = 0
	%papers_container.add_child(active_paper)
	active_paper.move_to_front()
	active_paper.marker_layer.stroke_finished.connect(_on_stroke_finished)
	active_paper.marker_layer.stroke_started.connect(_on_marker_drawing_started)
	active_paper.debug_overlay.text_renderer = active_paper.text_renderer
	active_paper.debug_overlay.tolerance = REDACTION_TOLERANCE

	var offset_pos := Vector2(randf_range(-30.0, 0.0), randf_range(-30.0, 0.0))
	if animate_in:
		AudioManager.play_paper_sfx("memo_spawn")
		# Teczka-anchored spawn animation
		var teczka_a := get_node_or_null("%Teczka") as Sprite2D
		var teczka_b := get_node_or_null("%Teczka2") as Sprite2D
		var spawn_global: Vector2
		if teczka_a != null and teczka_b != null:
			spawn_global = (teczka_a.global_position + teczka_b.global_position) * 0.5
		else:
			spawn_global = Vector2(1920, 461)  # hardcoded fallback if unique-name lookup fails
		var spawn_local: Vector2 = %papers_container.to_local(spawn_global)
		active_paper.position = spawn_local
		# Paper tumbles slightly as it emerges from briefcase
		active_paper.rotation = deg_to_rad(randf_range(-8.0, 8.0))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(active_paper, "position", offset_pos, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(active_paper, "rotation", 0.0, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Lock marker input during animation to prevent interaction before paper lands
		active_paper.marker_layer.set_locked(true)
		tween.tween_callback(func() -> void: active_paper.marker_layer.set_locked(false))
	else:
		active_paper.position = offset_pos
		active_paper.rotation = 0.0


func _spawn_fresh_paper(animate_in: bool) -> void:
	_prepare_paper_spawn(animate_in)
	session = _build_session()
	_load_session()
	_refresh_postit_and_penalty()
	_paper_index += 1


func _build_session() -> Dictionary:
	var template := WordManager.templates[rng.randi_range(0, WordManager.templates.size() - 1)]
	var word_count := 3 if template.find("{illegal_c}") != -1 else 2
	var planted_canonicals := WordManager.pick_random_canonicals(word_count)
	var phase := _current_phase()
	var planted_display := _pick_display_variants_for_planted(planted_canonicals, phase)

	# Build preview intel display variants so decoy selection can target them.
	# NOTE: actual intel ROLL still happens via _roll_toilet_intel — this is a
	# preview pass to give the decoy picker something to match against.
	var preview_intel_display: Array[String] = []
	for c in planted_canonicals:
		var mode := _intel_variant_mode_for_phase(phase)
		var pool := WordManager.display_variants(c, mode)
		if pool.is_empty():
			pool = [c]
		preview_intel_display.append(pool[rng.randi_range(0, pool.size() - 1)])

	var decoy_canonicals := _pick_decoy_canonicals(planted_canonicals, preview_intel_display, phase)
	var decoy_text := _build_decoy_text(decoy_canonicals, phase)

	var text := _build_document_text(template, planted_display) + decoy_text
	return {
		"text": text,
		"planted_words": planted_display,           # what the renderer sees / flags
		"planted_canonicals": planted_canonicals,   # source of truth for matching
		"planted_total": word_count,
		"decoys": decoy_canonicals,                 # canonicals chosen as decoys
		"word_scores": {} as Dictionary,
		"strokes": [] as Array[PackedVector2Array],
		"stamped": false,
		"phase": int(phase),                        # for debug / playtest tooling
	}


## Returns the current game phase based on elapsed shift time.
func _current_phase() -> Phase:
	if _onboarding_step != OnboardingStep.DONE:
		return Phase.TEACHING
	var elapsed := 180.0 - clock.time_left
	if elapsed < PHASE_TEACHING_END_S:
		return Phase.TEACHING
	if elapsed < PHASE_LIGHT_END_S:
		return Phase.LIGHT
	return Phase.FULL


## Returns the VariantMode to use for a single planted paper slot given the current phase.
## TEACHING → CANONICAL; LIGHT/FULL → 50/50 CANONICAL/TYPO per slot.
## Call this PER PLANTED SLOT, not once per paper, so each slot gets its own independent draw.
## SYNONYM is never returned here: synonyms are intel-only.
func _paper_variant_mode_for_phase(phase: Phase) -> WordManager.VariantMode:
	match phase:
		Phase.TEACHING:
			return WordManager.VariantMode.CANONICAL
		Phase.LIGHT, Phase.FULL:
			if rng.randf() < 0.5:
				return WordManager.VariantMode.TYPO
			return WordManager.VariantMode.CANONICAL
	return WordManager.VariantMode.CANONICAL


## Returns the VariantMode to use for a single intel slot given the current phase.
## TEACHING/LIGHT → CANONICAL; FULL → 50/50 CANONICAL/SYNONYM per slot.
## Call this PER INTEL SLOT so each slot gets its own independent random draw.
func _intel_variant_mode_for_phase(phase: Phase) -> WordManager.VariantMode:
	match phase:
		Phase.TEACHING, Phase.LIGHT:
			return WordManager.VariantMode.CANONICAL
		Phase.FULL:
			if rng.randf() < 0.5:
				return WordManager.VariantMode.SYNONYM
			return WordManager.VariantMode.CANONICAL
	return WordManager.VariantMode.CANONICAL


## For each canonical in the array, picks one random display variant according to the
## phase's paper-variant rule.  If the variant pool is empty (defensive fallback),
## the canonical itself is used.  Returns an array of the same length as canonicals.
func _pick_display_variants_for_planted(canonicals: Array[String], phase: Phase) -> Array[String]:
	var result: Array[String] = []
	for canon in canonicals:
		var mode := _paper_variant_mode_for_phase(phase)
		var pool: Array = WordManager.display_variants(canon, mode)
		if pool.is_empty():
			result.append(canon)
		else:
			result.append(pool[rng.randi_range(0, pool.size() - 1)])
	return result


## Standard Levenshtein edit distance on lowercased inputs.
## O(n*m) DP table — inputs are short (≤ 20 chars) so this is trivially fast.
func _edit_distance(a: String, b: String) -> int:
	var la := a.to_lower()
	var lb := b.to_lower()
	var n := la.length()
	var m := lb.length()
	if n == 0:
		return m
	if m == 0:
		return n
	var prev := []
	prev.resize(m + 1)
	for j in range(m + 1):
		prev[j] = j
	var curr := []
	curr.resize(m + 1)
	for i in range(1, n + 1):
		curr[0] = i
		for j in range(1, m + 1):
			var cost := 0 if la.unicode_at(i - 1) == lb.unicode_at(j - 1) else 1
			curr[j] = mini(mini(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
		for j in range(m + 1):
			prev[j] = curr[j]
	return prev[m]


## Selects decoy canonicals (NOT in planted set) whose display variants are
## visually close to one of the intel display strings, scaled by phase.
##
## Phase rules:
##   TEACHING → 0 decoys
##   LIGHT    → 1–2 decoys, similarity threshold edit-distance ≤ 4
##   FULL     → 2–4 decoys, similarity threshold edit-distance ≤ 2
##
## If too few similar candidates exist, tops up with random non-planted canonicals.
func _pick_decoy_canonicals(planted: Array[String], intel_display: Array[String], phase: Phase) -> Array[String]:
	if phase == Phase.TEACHING:
		return []

	var target_count: int
	var threshold: int
	if phase == Phase.LIGHT:
		target_count = rng.randi_range(1, 2)
		threshold = 4
	else:  # FULL
		target_count = rng.randi_range(2, 4)
		threshold = 2

	# Build eligible pool: canonicals not in planted, with at least one display
	# variant within threshold edit distance of any intel display string.
	var eligible: Array[String] = []
	var fallback: Array[String] = []

	for entry in WordManager.master_list:
		var canon: String = entry["canonical"]
		if canon in planted:
			continue

		fallback.append(canon)

		# Collect display variants for this candidate under TYPO_OR_SYNONYM mode.
		var variants: Array = WordManager.display_variants(canon, WordManager.VariantMode.TYPO_OR_SYNONYM)
		if variants.is_empty():
			variants = [canon]

		# Check minimum edit distance from any candidate variant to any intel display.
		var min_dist := 9999
		for v in variants:
			for id_word in intel_display:
				var d := _edit_distance(v, id_word)
				if d < min_dist:
					min_dist = d

		if min_dist <= threshold:
			eligible.append(canon)

	# Shuffle and take target_count from eligible first, then top up from fallback.
	eligible.shuffle()
	fallback.shuffle()

	var result: Array[String] = []
	for c in eligible:
		if result.size() >= target_count:
			break
		result.append(c)

	# Top up with random non-planted canonicals if not enough eligible.
	for c in fallback:
		if result.size() >= target_count:
			break
		if c not in result:
			result.append(c)

	return result


## Renders decoy canonicals as a clerk-sounding appended sentence.
## Returns "" if canonicals is empty (TEACHING phase).
## Returns a string with a leading space so it appends cleanly to template text.
func _build_decoy_text(decoy_canonicals: Array[String], phase: Phase) -> String:
	if decoy_canonicals.is_empty():
		return ""

	var lead_ins: Array[String] = [
		"Cross-reference also noted: %s.",
		"Additional surveillance flags: %s.",
		"Field margin notes: %s.",
		"See related entries: %s.",
	]
	var lead_in: String = lead_ins[rng.randi_range(0, lead_ins.size() - 1)]

	# Pick a display variant for each decoy (paper-side obfuscation rule).
	var display_words: Array[String] = []
	for canon in decoy_canonicals:
		var mode := _paper_variant_mode_for_phase(phase)
		var pool: Array = WordManager.display_variants(canon, mode)
		if pool.is_empty():
			pool = [canon]
		display_words.append(pool[rng.randi_range(0, pool.size() - 1)])

	# Join with ", " and " and " before last item if 2+.
	var joined: String
	if display_words.size() == 1:
		joined = display_words[0]
	else:
		var all_but_last := display_words.slice(0, display_words.size() - 1)
		joined = ", ".join(all_but_last) + " and " + display_words[display_words.size() - 1]

	return " " + (lead_in % joined)


func _build_document_text(template: String, document_words: Array[String]) -> String:
	var text := template
	var random_name := WordManager.names[rng.randi_range(0, WordManager.names.size() - 1)]
	text = text.replace("{name}", random_name)
	var slot_words := document_words.duplicate()
	slot_words.shuffle()
	text = text.replace("{illegal_a}", slot_words[0])
	text = text.replace("{illegal_b}", slot_words[1])
	if text.find("{illegal_c}") != -1 and slot_words.size() > 2:
		text = text.replace("{illegal_c}", slot_words[2])
	return text


func _load_session() -> void:
	if active_paper == null:
		return
	var text_renderer := _text_renderer()
	var marker_layer := _marker_layer()
	var debug_overlay := _debug_overlay()
	text_renderer.set_document(session["text"], WordManager.current_toilet_words)
	text_renderer.set_planted_canonicals(session["planted_canonicals"])
	text_renderer.set_decoy_canonicals(session.get("decoys", []))
	var tutorial_targets: Array = session.get("tutorial_targets", [])
	if session.get("hide_target_words", false):
		text_renderer.set_transparent_words(tutorial_targets)
	else:
		text_renderer.set_transparent_words([])
	text_renderer.show_letterhead = session.get("show_letterhead", true)
	active_paper.show_letterhead = text_renderer.show_letterhead
	marker_layer.clear_strokes()
	marker_layer.clear_word_marks()
	marker_layer.set_locked(false)
	text_renderer.reset_review()
	debug_overlay.clear_stroke_samples()
	active_paper.set_stamp_visible(session.get("stamped", false))


func _save_session() -> void:
	var marker_layer := _marker_layer()
	if marker_layer:
		session["strokes"] = _duplicate_strokes(marker_layer.strokes)


# ---------------------------------------------------------------------------
# Toilet intel
# ---------------------------------------------------------------------------

func _on_gimme_toilet_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		toilet_pull()


func toilet_pull() -> void:
	if _shift_ending:
		return
	AudioManager.play_sfx("toilet_handle_pull", 1.0, -20.0)
	if _onboarding_step == OnboardingStep.TOILET_LESSON and _onboarding_substep == 0:
		_onboarding_toilet_pull()
		return
	if _onboarding_step != OnboardingStep.DONE:
		return
	if active_paper == null:
		_spawn_fresh_paper(false)
		_roll_toilet_intel(true)
		return

	var original_pos := Vector2.ZERO
	var offset_pos := original_pos + Vector2(0, 100)
	var trans_time := 0.2

	var tween := create_tween()
	tween.tween_property(%toilet_handle, "position", offset_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(%toilet_handle, "position", original_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_advance_to_new_paper)


func _advance_to_new_paper() -> void:
	if _onboarding_step != OnboardingStep.DONE:
		return
	# Lock current paper score: simply save the current session strokes (already done at stroke time).
	# No submit penalty: unmarked planted words DO NOT incur a -0.5 deduction.
	_save_session()
	_check_and_apply_stamp()
	_spawn_fresh_paper(true)   # builds new session including planted_canonicals
	_roll_toilet_intel(true)   # rolls intel from new paper's canonicals


func _register_player_activity() -> void:
	_idle_time = 0.0
	if _attract_tween != null:
		_stop_handle_attract()


func _start_handle_attract() -> void:
	AudioManager.play_sfx("handle_attract_creak", 1.0, -2.0)
	var handle := %toilet_handle
	_attract_tween = create_tween().set_loops()
	_attract_tween.tween_property(handle, "rotation", ATTRACT_SWAY_RAD, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_attract_tween.tween_property(handle, "rotation", -ATTRACT_SWAY_RAD, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_attract_tween.tween_property(handle, "rotation", 0.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var flash := create_tween()
	flash.tween_property(handle, "modulate", Color(1.6, 1.6, 1.3), 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	flash.tween_property(handle, "modulate", Color.WHITE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _stop_handle_attract() -> void:
	if _attract_tween != null and _attract_tween.is_valid():
		_attract_tween.kill()
	_attract_tween = null
	var handle := %toilet_handle
	var settle := create_tween().set_parallel(true)
	settle.tween_property(handle, "rotation", 0.0, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	settle.tween_property(handle, "modulate", Color.WHITE, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _spawn_toilet_intel_messages(display_words: Array[String]) -> void:
	_expire_existing_toilet_intel()
	if not display_words.is_empty():
		AudioManager.play_toilet_intel_sfx("intel_strip_spawn")

	var intel_count := display_words.size()
	var y_pad_perct := 0.2
	var y_padding := viewport_size.y * y_pad_perct
	var y_spacer := (viewport_size.y * (1.0 - y_pad_perct) * 0.8) / maxi(1, intel_count)

	for i in range(intel_count):
		var toilet_msg = TOILET_SCN.instantiate()
		%toilet_msgs_container.add_child(toilet_msg)
		toilet_msg.position.y = -100
		toilet_msg.set_label(display_words[i])
		toilet_msg.prep_tween()

		var msg_tween := create_tween().set_parallel(true)
		var target_x := randf_range(-50, 50)
		var target_y := y_padding + (y_spacer * i)
		target_y += randf_range(-1 * y_padding * 0.1, y_padding * 0.1)
		msg_tween.tween_property(toilet_msg, "position:y", target_y, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		msg_tween.tween_property(toilet_msg, "position:x", target_x, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _roll_toilet_intel(animate_msgs: bool = true) -> void:
	# Source intel from the current paper's planted canonicals.
	var canonicals: Array[String] = []
	if not session.is_empty() and session.has("planted_canonicals"):
		canonicals = session["planted_canonicals"]
	if canonicals.is_empty():
		# No paper yet — clear intel state and return.
		# After this task, _roll_toilet_intel is always called AFTER _spawn_fresh_paper,
		# so this guard mainly protects against accidental ordering regressions.
		WordManager.current_toilet_canonicals = []
		WordManager.current_toilet_words = []
		return

	var phase := _current_phase()
	var display_words: Array[String] = []
	for c in canonicals:
		var mode := _intel_variant_mode_for_phase(phase)
		var pool := WordManager.display_variants(c, mode)
		if pool.is_empty():
			pool = [c]
		display_words.append(pool[rng.randi_range(0, pool.size() - 1)])

	WordManager.current_toilet_canonicals = canonicals.duplicate()
	WordManager.current_toilet_words = display_words

	if not animate_msgs:
		if session.has("text"):
			_apply_toilet_to_current_paper()
		return

	_spawn_toilet_intel_messages(display_words)

	if session.has("text"):
		_apply_toilet_to_current_paper()


func _apply_toilet_to_current_paper() -> void:
	# Invariant: does NOT touch session["word_scores"]. Per-word scores are locked
	# at stroke time and must not be re-evaluated when intel changes.
	_save_session()
	_text_renderer().set_forbidden_words(WordManager.current_toilet_words)
	_load_session_strokes()
	_refresh_postit_and_penalty()


func _load_session_strokes() -> void:
	var marker_layer := _marker_layer()
	var text_renderer := _text_renderer()
	marker_layer.clear_strokes()
	marker_layer.clear_word_marks()
	for stroke in session.get("strokes", []):
		if stroke is PackedVector2Array:
			marker_layer.strokes.append(stroke.duplicate())
			marker_layer.stroke_colors.append(marker_layer.marker_color)
	marker_layer.set_locked(false)
	text_renderer.reset_review()


# ---------------------------------------------------------------------------
# Briefing / new paper
# ---------------------------------------------------------------------------

# DEAD CODE (phase-7): briefcase is scenery. Functions retained for diff clarity; safe to delete in a follow-up.
func _on_send_to_briefieng_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_send_to_briefing()


# DEAD CODE (phase-7): briefcase is scenery. Functions retained for diff clarity; safe to delete in a follow-up.
func _send_to_briefing(advance_paper: bool = true) -> void:
	if active_paper == null:
		return

	_save_session()

	# Stamp eligibility: all planted words marked (partial or full) AND zero wrongs.
	var word_scores: Dictionary = session.get("word_scores", {})
	var text_renderer := _text_renderer()
	var marked_planted := 0
	var wrongs := 0
	if text_renderer != null:
		for i in range(text_renderer.word_boxes.size()):
			var box: Dictionary = text_renderer.word_boxes[i]
			var entry: Dictionary = word_scores.get(i, {})
			var state: String = entry.get("state", "untouched")
			if box.get("planted", false) and (state == "partial" or state == "full"):
				marked_planted += 1
			if state == "wrong":
				wrongs += 1

	var earned_stamp: bool = marked_planted == session.get("planted_total", 0) and wrongs == 0
	if earned_stamp:
		session["stamped"] = true
		active_paper.set_stamp_visible(true)

	_refresh_postit_and_penalty()

	if not advance_paper:
		return

	if earned_stamp:
		var tween := create_tween()
		tween.tween_interval(1.25)
		tween.tween_callback(_spawn_fresh_paper.bind(true))
	else:
		_spawn_fresh_paper(true)


# ---------------------------------------------------------------------------
# Scoring / post-it
# ---------------------------------------------------------------------------

func _check_and_apply_stamp() -> void:
	# Stamp eligibility: all planted words marked (partial or full) AND zero wrongs.
	# Idempotent — only fires the visual tween on the transition to stamped.
	if session.get("stamped", false):
		return
	var word_scores: Dictionary = session.get("word_scores", {})
	var text_renderer := _text_renderer()
	var marked_planted := 0
	var wrongs := 0
	if text_renderer != null:
		for i in range(text_renderer.word_boxes.size()):
			var box: Dictionary = text_renderer.word_boxes[i]
			var entry: Dictionary = word_scores.get(i, {})
			var state: String = entry.get("state", "untouched")
			if box.get("planted", false) and (state == "partial" or state == "full"):
				marked_planted += 1
			if state == "wrong":
				wrongs += 1

	var earned_stamp: bool = marked_planted == session.get("planted_total", 0) and wrongs == 0
	if earned_stamp:
		session["stamped"] = true
		active_paper.set_stamp_visible(true)
		_shift_stamps += 1


func _on_stroke_finished(_stroke: PackedVector2Array) -> void:
	_notify_fly_marker_idle()
	_save_session()
	if _shift_ending:
		_shift_report_check_progress()
		return
	if _topic_intro_active:
		_topic_intro_check_progress()
		return
	if _onboarding_step != OnboardingStep.DONE:
		_onboarding_check_progress()
		return
	# Run incremental scorer first — locks per-word deltas and mutates shift_score.
	var stroke_index := _marker_layer().strokes.size() - 1
	var score_result := _score_stroke_incremental(stroke_index)
	_color_stroke_by_deltas(stroke_index, score_result)
	var stroke_deltas: Array = score_result.get("deltas", [])
	# Spawn a floating score popup for each word transition this stroke caused.
	for d in stroke_deltas:
		if d.get("delta", 0.0) != 0.0:
			_spawn_score_popup(d["delta"], d["rect"])
	_refresh_postit_and_penalty()
	# Award stamp the instant the player completes a perfect page, not on pull.
	_check_and_apply_stamp()


func _color_stroke_by_deltas(stroke_index: int, score_result: Dictionary) -> void:
	# Spec §6: sum < 0 → red; sum >= 0 (including ==0) → leave as marker color (already set at draw time).
	var marker_layer := _marker_layer()
	if marker_layer == null or marker_layer.strokes.is_empty():
		return
	if score_result.get("sum", 0.0) < 0.0:
		AudioManager.play_sfx("wrong_mark_accent")
		if stroke_index < marker_layer.stroke_colors.size():
			marker_layer.stroke_colors[stroke_index] = Color(0.75, 0.1, 0.1, 0.9)
	marker_layer.queue_redraw()


func _spawn_score_popup(delta: float, rect: Rect2) -> void:
	if active_paper == null:
		return
	# Color and text per spec §6 delta mapping.
	var text: String
	var color: Color
	if delta == 2.0:
		text = "+2"
		color = Color(0.2, 0.75, 0.3, 1.0)
	elif delta == 1.0:
		text = "+1"
		color = Color(0.2, 0.75, 0.3, 1.0)
	elif delta == -0.5:
		text = "-0.5"
		color = Color(0.75, 0.1, 0.1, 1.0)
	else:
		text = "%+g" % delta
		color = Color(0.2, 0.75, 0.3, 1.0) if delta > 0.0 else Color(0.75, 0.1, 0.1, 1.0)

	var popup: ScorePopup = ScorePopupScene.instantiate()
	# Add popup as child of active_paper with z_index above MarkerGroup (which has no explicit
	# z_index, defaulting to 0). z_index = 1 ensures popups render above red ink strokes.
	popup.z_index = 1
	# Position in paper-local space: text_renderer.position + rect center converts
	# text-renderer-local rect coordinates into paper-local coordinates.
	var text_renderer := _text_renderer()
	var center := text_renderer.position + rect.get_center() if text_renderer else rect.get_center()
	popup.position = center
	active_paper.add_child(popup)
	popup.show_delta(text, color)


func _spawn_clock_time_popup() -> void:
	var clock_node: Node2D = %clock_scn
	var popup: ScorePopup = ScorePopupScene.instantiate()
	clock_node.add_child(popup)
	popup.position = COFFEE_TIME_POPUP_OFFSET
	popup.show_delta("+%ds" % int(COFFEE_TIME_BONUS_S), Color(0.2, 0.75, 0.3, 1.0))
	AudioManager.play_sfx("clock_time_ping")


func _refresh_postit_and_penalty() -> void:
	if active_paper == null:
		return
	if _onboarding_step != OnboardingStep.DONE:
		return
	var text_renderer := _text_renderer()
	var word_scores: Dictionary = session.get("word_scores", {})
	var marked_planted := 0
	var wrongs := 0
	if text_renderer != null:
		for i in range(text_renderer.word_boxes.size()):
			var box: Dictionary = text_renderer.word_boxes[i]
			var entry: Dictionary = word_scores.get(i, {})
			var state: String = entry.get("state", "untouched")
			if box.get("planted", false) and (state == "partial" or state == "full"):
				marked_planted += 1
			if state == "wrong":
				wrongs += 1
	active_paper.set_postit(marked_planted, session.get("planted_total", 0))
	active_paper.set_penalty(wrongs)
	active_paper.set_shift_score(WordManager.shift_score)


func _word_coverage_tier_from_strokes(box: Dictionary, all_samples: Array[PackedVector2Array]) -> String:
	# Returns "none" | "half" | "full" using existing COVERAGE_* constants.
	# Shared helper used by _score_stroke_incremental.
	var grown: Rect2 = box["rect"].grow(REDACTION_TOLERANCE)
	var cell_total := maxi(1, ceili(grown.size.x / COVERAGE_CELL_WIDTH))
	var touched := {}
	for samples in all_samples:
		for point in samples:
			if not grown.has_point(point):
				continue
			var ci := clampi(
				floori((point.x - grown.position.x) / COVERAGE_CELL_WIDTH),
				0,
				cell_total - 1
			)
			touched[ci] = true
	return _coverage_tier(touched.size(), cell_total)


# Applies the spec §2 transition table per word_box. Must be called after
# _save_session so session["strokes"] is current. Returns a summary dict:
#   { "deltas": Array[Dictionary], "sum": float, "wrongs_added": int }
# Each element of deltas: { word_index: int, delta: float, new_state: String, rect: Rect2 }
func _score_stroke_incremental(_stroke_index: int) -> Dictionary:
	var text_renderer := _text_renderer()
	if text_renderer == null:
		return {"deltas": [], "sum": 0.0, "wrongs_added": 0}

	# Build cumulative samples from ALL strokes on this paper.
	var all_samples := _stroke_samples_in_text_space_from_array(session.get("strokes", []))

	var deltas: Array = []
	var total_sum := 0.0
	var wrongs_added := 0

	for i in range(text_renderer.word_boxes.size()):
		var box: Dictionary = text_renderer.word_boxes[i]

		# Retrieve prior scoring state (missing key == untouched / 0.0).
		var word_scores: Dictionary = session.get("word_scores", {})
		var prior_entry: Dictionary = word_scores.get(i, {"state": "untouched", "points": 0.0})
		var prior_state: String = prior_entry.get("state", "untouched")

		# Row 6: prior already at full / wrong → no-op. (partial may upgrade to full below.)
		if prior_state == "full" or prior_state == "wrong":
			continue

		var tier := _word_coverage_tier_from_strokes(box, all_samples)

		# Tier "none" → no transition regardless.
		if tier == "none":
			continue

		var planted: bool = box.get("planted", false)
		var on_intel: bool = box.get("illegal", false)
		var is_target: bool = planted and on_intel

		var new_state: String = ""
		var delta: float = 0.0
		var do_transition := false

		if is_target:
			if prior_state == "untouched":
				if tier == "half":
					# Row 1: untouched → partial, +1.
					new_state = "partial"
					delta = 1.0
					do_transition = true
				else:  # tier == "full"
					# Row 2: untouched → full, +2.
					new_state = "full"
					delta = 2.0
					do_transition = true
			elif prior_state == "partial" and tier == "full":
				# Row 3: partial → full, +1 (delta).
				new_state = "full"
				delta = 1.0
				do_transition = true
			# Row 4: partial + tier==half → no-op (already partial, can't downgrade).
		else:
			if prior_state == "untouched":
				# Row 5: not (planted ∧ on-intel), coverage reached, prior untouched → wrong.
				new_state = "wrong"
				delta = -0.5
				do_transition = true
			# Row 6 covers prior==partial here too (partial stays partial for non-targets).

		if not do_transition:
			continue

		# Apply transition.
		var prior_points: float = prior_entry.get("points", 0.0)
		if not session.has("word_scores"):
			session["word_scores"] = {}
		session["word_scores"][i] = {"state": new_state, "points": prior_points + delta}
		WordManager.shift_score += delta
		total_sum += delta
		if new_state == "wrong":
			wrongs_added += 1

		deltas.append({
			"word_index": i,
			"delta": delta,
			"new_state": new_state,
			"rect": box["rect"],
		})

	return {"deltas": deltas, "sum": total_sum, "wrongs_added": wrongs_added}


func _coverage_tier(touched: int, total: int) -> String:
	if touched < COVERAGE_MIN_CELLS:
		return "none"
	var ratio := float(touched) / float(total)
	if ratio >= COVERAGE_FULL_RATIO:
		return "full"
	if ratio >= COVERAGE_HALF_RATIO:
		return "half"
	return "none"


func _sample_stroke(stroke: PackedVector2Array) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for index in range(stroke.size() - 1):
		var start := stroke[index]
		var end := stroke[index + 1]
		var distance := start.distance_to(end)
		var sample_count := maxi(1, ceili(distance / SAMPLE_STEP))
		for sample_index in range(sample_count + 1):
			samples.append(start.lerp(end, float(sample_index) / float(sample_count)))
	return samples


func _marker_point_to_text_local(point: Vector2) -> Vector2:
	return active_paper.marker_point_to_text_local(point)


func _stroke_samples_in_text_space(stroke: PackedVector2Array) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for point in _sample_stroke(stroke):
		samples.append(_marker_point_to_text_local(point))
	return samples


func _stroke_samples_in_text_space_from_array(strokes: Array) -> Array[PackedVector2Array]:
	var all_samples: Array[PackedVector2Array] = []
	for stroke in strokes:
		if stroke is PackedVector2Array:
			all_samples.append(_stroke_samples_in_text_space(stroke))
	return all_samples


func _duplicate_strokes(source: Array) -> Array[PackedVector2Array]:
	var copy: Array[PackedVector2Array] = []
	for stroke in source:
		if stroke is PackedVector2Array:
			copy.append(stroke.duplicate())
	return copy


# ---------------------------------------------------------------------------
# Cofefe / end shift
# ---------------------------------------------------------------------------

func _connect_cofefe() -> void:
	var cofefe: Node2D = %Cofefe
	if not cofefe.has_signal("sip_requested"):
		return
	cofefe.sip_requested.connect(_on_cofefe_sip)
	cofefe.mug_placed.connect(_on_cofefe_placed)
	cofefe.drag_started.connect(_on_cofefe_drag_started)
	cofefe.drag_ended.connect(_on_cofefe_drag_ended)


func _connect_point_light() -> void:
	var light := get_node_or_null("%PointLight2D")
	if light == null or not light.has_signal("flicker_off"):
		return
	light.flicker_off.connect(_on_point_light_flicker_off)
	light.flicker_on.connect(_on_point_light_flicker_on)


func _on_point_light_flicker_off() -> void:
	_point_light_lit = false
	_refresh_kawa_cien(0.0)
	_refresh_popielniczka_cien(0.0)
	_refresh_papieros_cien(0.0)
	if not _shift_ending:
		AudioManager.play_sfx("lamp_flicker_click", 1.0, -4.0)


func _on_point_light_flicker_on() -> void:
	_point_light_lit = true
	_refresh_kawa_cien(0.0)
	_refresh_popielniczka_cien(0.0)
	_refresh_papieros_cien(0.0)
	if not _shift_ending:
		AudioManager.play_sfx("lamp_flicker_click", 1.0, -6.0)


func _release_point_light_override() -> void:
	var light := get_node_or_null("%PointLight2D")
	if light and light.has_method("release_lamp_override"):
		light.release_lamp_override()


func _force_point_light(on: bool) -> void:
	var light := get_node_or_null("%PointLight2D")
	if light and light.has_method("force_lamp"):
		light.force_lamp(on)


func _build_shift_report_session() -> Dictionary:
	var text := ShiftReportContent.report_text(
		WordManager.shift_score,
		_paper_index,
		_shift_stamps
	)
	return _build_tutorial_session(text, ShiftReportContent.REPORT_TARGETS)


func _shift_report_check_progress() -> void:
	if not _tutorial_all_targets_covered(ShiftReportContent.REPORT_TARGETS):
		return
	_end_shift()


func _set_redaction_loop_animations(active: bool) -> void:
	if active:
		_palec_animation.speed_scale = clock.get_decor_speed_scale()
		_palec_animation.play("palec")
	else:
		_palec_animation.stop()


func _begin_shift_closure() -> void:
	if _shift_ending:
		return
	_shift_ending = true
	_set_redaction_loop_animations(false)
	clock.stop_shift()
	_stop_handle_attract()
	_force_point_light(false)
	AudioManager.play_sfx("lamp_final_off")
	AudioManager.play_sfx("shift_report_arrive")

	var paper_to_exit: GamePaper = active_paper
	if paper_to_exit:
		active_paper = null
		_disconnect_paper_signals(paper_to_exit)

	var ui_exit_tween := _tween_shift_closure_ui_out(paper_to_exit)
	await ui_exit_tween.finished

	_force_point_light(true)
	AudioManager.play_sfx("lamp_relight")

	var report_session := _build_shift_report_session()
	_spawn_scripted_paper(report_session, true, DocumentScenes.onboarding("shift_report"))
	if active_paper:
		active_paper.set_onboarding_ui(true)


func _reset_coffee_cigarette_for_shift() -> void:
	_twitch_force = 0
	_stop_hand_twitch()
	if _coffee_jitter_timer:
		_coffee_jitter_timer.stop()
	var papieros = %Papieros
	if papieros.has_method("reset_for_shift"):
		papieros.reset_for_shift()
	var cofefe: Node2D = %Cofefe
	if cofefe.has_method("reset_for_shift"):
		cofefe.reset_for_shift()


func _setup_coffee_jitter_timer() -> void:
	_coffee_jitter_timer = Timer.new()
	_coffee_jitter_timer.one_shot = true
	add_child(_coffee_jitter_timer)
	_coffee_jitter_timer.timeout.connect(_on_coffee_jitter_timer_timeout)


func _jitter_interval_for_force(force: int) -> float:
	var base := rng.randf_range(COFFEE_JITTER_MIN_S, COFFEE_JITTER_MAX_S)
	if force <= 0:
		return base
	return maxf(0.35, base / (1.0 + float(force - 1) * TWITCH_FORCE_INTERVAL_STEP))


func _twitch_scale_for_force() -> float:
	return 1.0 + float(_twitch_force) * TWITCH_FORCE_OFFSET_STEP


func _schedule_coffee_jitter() -> void:
	if _twitch_force <= 0 or _onboarding_step != OnboardingStep.DONE:
		return
	if _coffee_jitter_timer == null:
		return
	_coffee_jitter_timer.start(_jitter_interval_for_force(_twitch_force))


func _on_coffee_jitter_timer_timeout() -> void:
	if _twitch_force <= 0 or _onboarding_step != OnboardingStep.DONE:
		return
	_twitch_right_hand()
	_schedule_coffee_jitter()


func _twitch_right_hand() -> void:
	var right_hand: Node2D = %RightHand
	if right_hand == null:
		return
	_stop_hand_twitch()
	if right_hand.has_method("suspend_follow"):
		right_hand.suspend_follow()
	var twitch_scale := _twitch_scale_for_force()
	AudioManager.play_sfx("hand_twitch", randf_range(0.92, 1.08), -3.0)
	var rest_global := right_hand.global_position
	var rest_rot := right_hand.rotation
	var vertical_base := -PI * 0.5 if rng.randf() > 0.5 else PI * 0.5
	var twitch_dir := Vector2.from_angle(
		vertical_base + rng.randf_range(-TWITCH_VERTICAL_SPREAD, TWITCH_VERTICAL_SPREAD)
	)
	var peak_global := rest_global + twitch_dir * HAND_TWITCH_OFFSET.length() * twitch_scale
	var rot_sign := 1.0 if rng.randf() > 0.5 else -1.0
	var peak_rot := rest_rot + rot_sign * HAND_TWITCH_ROT * twitch_scale
	_hand_jitter_active = true
	_sync_marker_jitter_to_hand()
	_hand_twitch_tween = create_tween()
	_hand_twitch_tween.tween_property(right_hand, "global_position", peak_global, HAND_TWITCH_OUT_S) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hand_twitch_tween.parallel().tween_property(right_hand, "rotation", peak_rot, HAND_TWITCH_OUT_S) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hand_twitch_tween.tween_property(right_hand, "global_position", rest_global, HAND_TWITCH_RETURN_S) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hand_twitch_tween.parallel().tween_property(right_hand, "rotation", rest_rot, HAND_TWITCH_RETURN_S) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hand_twitch_tween.finished.connect(_on_hand_twitch_finished, CONNECT_ONE_SHOT)


func _sync_marker_jitter_to_hand() -> void:
	var marker_layer := _marker_layer()
	var right_hand: Node2D = %RightHand
	if marker_layer == null or right_hand == null:
		return
	var hand_local := marker_layer.get_global_transform_with_canvas().affine_inverse() * right_hand.global_position
	var offset := hand_local - marker_layer.get_local_mouse_position()
	marker_layer.set_draw_position_offset(offset)


func _clear_marker_jitter() -> void:
	_hand_jitter_active = false
	var marker_layer := _marker_layer()
	if marker_layer:
		marker_layer.set_draw_position_offset(Vector2.ZERO)


func _on_hand_twitch_finished() -> void:
	_clear_marker_jitter()
	var right_hand: Node2D = %RightHand
	if right_hand and right_hand.has_method("resume_follow"):
		right_hand.resume_follow()


func _stop_hand_twitch() -> void:
	if _hand_twitch_tween and _hand_twitch_tween.is_valid():
		_hand_twitch_tween.kill()
	_hand_twitch_tween = null
	_clear_marker_jitter()
	var right_hand: Node2D = %RightHand
	if right_hand and right_hand.has_method("resume_follow"):
		right_hand.resume_follow()


func _connect_papieros() -> void:
	var papieros: Node2D = %Papieros
	if papieros.has_method("bind_ashtray"):
		papieros.bind_ashtray(%popielniczka)
	if not papieros.has_signal("puff_requested"):
		return
	papieros.puff_requested.connect(_on_papieros_puff)


func _on_papieros_puff() -> void:
	if _shift_ending:
		return
	if _onboarding_step != OnboardingStep.DONE:
		return
	# puff_requested fires after _puff_count increments; do not re-check can_puff() here.
	_twitch_force = maxi(0, _twitch_force - 1)
	_stop_hand_twitch()
	if _twitch_force > 0:
		_schedule_coffee_jitter()
	elif _coffee_jitter_timer:
		_coffee_jitter_timer.stop()


func _on_cofefe_sip() -> void:
	if _shift_ending:
		return
	if _onboarding_step != OnboardingStep.DONE:
		return
	var cofefe: Node2D = %Cofefe
	if cofefe.has_method("consume_sip") and not cofefe.consume_sip():
		return
	clock.add_time(COFFEE_TIME_BONUS_S)
	_spawn_clock_time_popup()
	_play_coffee_sip_flash()
	_twitch_force += 1
	_schedule_coffee_jitter()


func _play_coffee_sip_flash() -> void:
	var flash = get_node_or_null("%CoffeeSipFlash")
	if flash and flash.has_method("play_flash"):
		flash.play_flash()


func _on_cofefe_drag_started() -> void:
	if _shift_ending:
		return
	_cofefe_dragging = true
	_refresh_kawa_cien()
	if _onboarding_step != OnboardingStep.DONE:
		return
	var marker_layer := _marker_layer()
	if marker_layer:
		marker_layer.set_locked(true)


func _on_cofefe_drag_ended() -> void:
	_cofefe_dragging = false
	_refresh_kawa_cien()
	var marker_layer := _marker_layer()
	if marker_layer:
		marker_layer.set_locked(false)


func _on_cofefe_placed(global_center: Vector2, ring_radius: float, drop_vector: Vector2, drop_speed: float) -> void:
	if _onboarding_step != OnboardingStep.DONE:
		return
	if active_paper == null:
		return
	var marker_layer := _marker_layer()
	if marker_layer == null:
		return
	var ml_xf := marker_layer.get_global_transform_with_canvas()
	var local_center := ml_xf.affine_inverse() * global_center
	if not marker_layer.get_rect().has_point(local_center):
		return
	var local_rim := ml_xf.affine_inverse() * (global_center + Vector2(ring_radius, 0.0))
	var local_radius: float = local_center.distance_to(local_rim)
	marker_layer.apply_mug_smear(local_center, local_radius, drop_vector, drop_speed)


func _on_time_out() -> void:
	# No more submit penalty — the active paper's score is whatever was earned at mark-time.
	_save_session()
	_check_and_apply_stamp()
	_begin_shift_closure()


func _end_shift() -> void:
	WordManager.good_ending = WordManager.shift_score > 0
	get_tree().change_scene_to_file("res://scenes/flow/ending.tscn")
