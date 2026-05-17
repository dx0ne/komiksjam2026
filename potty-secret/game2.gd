extends Node2D

const REDACTION_TOLERANCE  := 12.0
const SAMPLE_STEP          := 6.0
const COVERAGE_CELL_WIDTH  := 8.0
const COVERAGE_HALF_RATIO  := 0.50
const COVERAGE_FULL_RATIO  := 0.70
const COVERAGE_MIN_CELLS   := 2
const TOILET_INTEL_COUNT   := 3
const WORDS_IN_DOCUMENT    := 3

const TOILET_SCN := preload("res://toilet_msg.tscn")
const PAPER_SCN  := preload("res://paper.tscn")

@onready var clock: ShiftClock = %clock_scn
@onready var _desk_stamp: Sprite2D = %Stempel

var viewport_size: Vector2
var rng := RandomNumberGenerator.new()

var active_paper: GamePaper = null
var session: Dictionary = {}


func _text_renderer() -> TextRenderer:
	return active_paper.text_renderer if active_paper else null


func _marker_layer() -> MarkerLayer:
	return active_paper.marker_layer if active_paper else null


func _debug_overlay() -> DebugOverlay:
	return active_paper.debug_overlay if active_paper else null


func _ready() -> void:
	rng.randomize()
	viewport_size = get_viewport().get_visible_rect().size

	%gimme_toilet_btn.gui_input.connect(_on_gimme_toilet_btn_gui_input)
	%send_to_briefieng.gui_input.connect(_on_send_to_briefieng_gui_input)
	clock.time_out.connect(_on_time_out)

	WordManager.shift_correct_illegal = 0
	if _desk_stamp:
		_desk_stamp.visible = false
	_spawn_fresh_paper(false)
	_roll_toilet_intel(true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			if _try_cofefe_click(mouse):
				return
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("rand_toilet_msg"):
		toilet_pull()
	if event.is_action_pressed("rand_document"):
		_send_to_briefing()
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
# Paper lifecycle
# ---------------------------------------------------------------------------

func _spawn_fresh_paper(animate_in: bool) -> void:
	if active_paper:
		if active_paper.marker_layer.stroke_finished.is_connected(_on_stroke_finished):
			active_paper.marker_layer.stroke_finished.disconnect(_on_stroke_finished)
		active_paper.queue_free()
		active_paper = null

	if _desk_stamp:
		_desk_stamp.visible = false

	active_paper = PAPER_SCN.instantiate()
	%papers_container.add_child(active_paper)
	active_paper.marker_layer.stroke_finished.connect(_on_stroke_finished)
	active_paper.debug_overlay.text_renderer = active_paper.text_renderer
	active_paper.debug_overlay.tolerance = REDACTION_TOLERANCE

	var offset_pos := Vector2(randf_range(-30.0, 0.0), randf_range(-30.0, 0.0))
	if animate_in:
		active_paper.position += Vector2(200, 100)
		var tween := create_tween()
		tween.tween_property(active_paper, "position", offset_pos, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		active_paper.position = offset_pos

	session = _build_session()
	_load_session()
	_refresh_postit_and_penalty()


func _build_session() -> Dictionary:
	var template := WordManager.templates[rng.randi_range(0, WordManager.templates.size() - 1)]
	var word_count := 3 if template.find("{illegal_c}") != -1 else 2
	var document_words := _pick_document_word_pool(word_count)
	var text := _build_document_text(template, document_words)
	return {
		"text": text,
		"document_words": document_words,
		"strokes": [] as Array[PackedVector2Array],
		"stamped": false,
	}


func _single_token_master_words() -> Array[String]:
	var pool: Array[String] = []
	for word in WordManager.master_list:
		if word.find(" ") == -1:
			pool.append(word)
	return pool if not pool.is_empty() else WordManager.master_list.duplicate()


func _pick_document_word_pool(count: int = WORDS_IN_DOCUMENT) -> Array[String]:
	var pool: Array[String] = _single_token_master_words()
	pool.shuffle()
	while pool.size() < count:
		pool.append_array(_single_token_master_words())
		pool.shuffle()
	var picked: Array[String] = []
	for i in range(mini(count, pool.size())):
		picked.append(pool[i])
	return picked


func _build_document_text(template: String, document_words: Array[String]) -> String:
	var text := template
	var name := WordManager.names[rng.randi_range(0, WordManager.names.size() - 1)]
	text = text.replace("{name}", name)
	text = text.replace("{illegal_a}", document_words[0])
	text = text.replace("{illegal_b}", document_words[1])
	if text.find("{illegal_c}") != -1 and document_words.size() > 2:
		text = text.replace("{illegal_c}", document_words[2])
	return text


func _load_session() -> void:
	if active_paper == null:
		return
	var text_renderer := _text_renderer()
	var marker_layer := _marker_layer()
	var debug_overlay := _debug_overlay()
	text_renderer.set_document(session["text"], WordManager.current_toilet_words)
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
	var original_pos := Vector2.ZERO
	var offset_pos := original_pos + Vector2(0, 100)
	var trans_time := 0.2

	var tween := create_tween()
	tween.tween_property(%toilet_handle, "position", offset_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(%toilet_handle, "position", original_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_roll_toilet_intel)


func _roll_toilet_intel(animate_msgs: bool = true) -> void:
	for child in %toilet_msgs_container.get_children():
		child.queue_free()

	WordManager.current_toilet_words = _pick_toilet_words_for_session()

	if not animate_msgs:
		if session.has("text"):
			_apply_toilet_to_current_paper()
		return

	var y_pad_perct := 0.2
	var y_padding := viewport_size.y * y_pad_perct
	var y_spacer := (viewport_size.y * (1.0 - y_pad_perct) * 0.8) / TOILET_INTEL_COUNT

	for i in range(WordManager.current_toilet_words.size()):
		var toilet_msg = TOILET_SCN.instantiate()
		%toilet_msgs_container.add_child(toilet_msg)
		toilet_msg.position.y = -100
		toilet_msg.set_label(WordManager.current_toilet_words[i])
		toilet_msg.prep_tween()

		var tween := create_tween().set_parallel(true)
		var target_x := randf_range(-50, 50)
		var target_y := y_padding + (y_spacer * i)
		target_y += randf_range(-1 * y_padding * 0.1, y_padding * 0.1)
		tween.tween_property(toilet_msg, "position:y", target_y, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(toilet_msg, "position:x", target_x, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	if session.has("text"):
		_apply_toilet_to_current_paper()


func _pick_toilet_words_for_session() -> Array[String]:
	var pool: Array = session.get("document_words", [])
	if pool.is_empty():
		return WordManager.pick_random_words(TOILET_INTEL_COUNT)
	var picks: Array[String] = []
	for word in pool:
		picks.append(word)
	picks.shuffle()
	var count := mini(TOILET_INTEL_COUNT, picks.size())
	var batch: Array[String] = []
	for i in range(count):
		batch.append(picks[i])
	return batch


func _apply_toilet_to_current_paper() -> void:
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

func _on_send_to_briefieng_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_send_to_briefing()


func _send_to_briefing(advance_paper: bool = true) -> void:
	if active_paper == null:
		return

	_save_session()
	var result := _evaluate_paper(session["text"], WordManager.current_toilet_words, session["strokes"])

	WordManager.shift_correct_illegal += result["correct_illegal"]

	var earned_stamp: bool = bool(result["all_illegal_marked"]) and int(result["false_redactions"]) == 0
	if earned_stamp:
		session["stamped"] = true
		active_paper.set_stamp_visible(true)
		if _desk_stamp:
			_desk_stamp.visible = true

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

func _on_stroke_finished(stroke: PackedVector2Array) -> void:
	_save_session()
	var result := _evaluate_paper(
		session["text"],
		WordManager.current_toilet_words,
		session["strokes"]
	)
	_color_stroke_by_result(stroke, result)
	_refresh_postit_and_penalty()


func _color_stroke_by_result(stroke: PackedVector2Array, result: Dictionary) -> void:
	var marker_layer := _marker_layer()
	var text_renderer := _text_renderer()
	if marker_layer.strokes.is_empty():
		return
	var stroke_index := marker_layer.strokes.size() - 1
	var touched_illegal := false
	var touched_legal := false

	var samples := _stroke_samples_in_text_space(stroke)
	var lookup := _toilet_lookup(WordManager.current_toilet_words)
	for box in text_renderer.word_boxes:
		var grown: Rect2 = box["rect"].grow(REDACTION_TOLERANCE)
		for point in samples:
			if not grown.has_point(point):
				continue
			if box.get("illegal", false) and lookup.has(box["word"]):
				touched_illegal = true
			elif not box.get("illegal", false):
				touched_legal = true

	if touched_legal and not touched_illegal:
		if stroke_index < marker_layer.stroke_colors.size():
			marker_layer.stroke_colors[stroke_index] = Color(0.75, 0.1, 0.1, 0.9)
		if active_paper:
			var result_live := _evaluate_paper(
				session["text"],
				WordManager.current_toilet_words,
				session["strokes"]
			)
			active_paper.set_penalty(result_live["false_redactions"])
	marker_layer.queue_redraw()


func _refresh_postit_and_penalty() -> void:
	if active_paper == null:
		return
	var result := _evaluate_paper(
		session.get("text", ""),
		WordManager.current_toilet_words,
		session.get("strokes", [])
	)
	active_paper.set_postit(result["correct_illegal"], result["illegal_count"])
	active_paper.set_shift_score(WordManager.shift_correct_illegal)
	active_paper.set_penalty(result["false_redactions"])


func _evaluate_paper(text: String, toilet_words: Array[String], strokes: Array) -> Dictionary:
	var text_renderer := _text_renderer()
	var marker_layer := _marker_layer()
	var restore_text := text_renderer.document_text
	var restore_forbidden := text_renderer.illegal_words.duplicate()
	var restore_strokes := _duplicate_strokes(marker_layer.strokes)
	var restore_colors: Array[Color] = []
	for color in marker_layer.stroke_colors:
		restore_colors.append(color)

	text_renderer.set_document(text, toilet_words)
	marker_layer.clear_strokes()
	for stroke in strokes:
		if stroke is PackedVector2Array:
			marker_layer.strokes.append(stroke)

	var all_samples := _stroke_samples_in_text_space_from_array(strokes)

	var correct_illegal := 0
	var marked_illegal := 0
	var missed_illegal := 0
	var false_redactions := 0
	var illegal_count := 0

	for box in text_renderer.word_boxes:
		if not box.get("illegal", false):
			continue
		illegal_count += 1

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

		var tier := _coverage_tier(touched.size(), cell_total)
		if tier != "none":
			marked_illegal += 1
		match tier:
			"full", "half":
				correct_illegal += 1
			_:
				missed_illegal += 1

	for box in text_renderer.word_boxes:
		if box.get("illegal", false):
			continue
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
		var tier := _coverage_tier(touched.size(), cell_total)
		if tier == "full" or tier == "half":
			false_redactions += 1

	var all_illegal_marked := illegal_count > 0 and missed_illegal == 0 and marked_illegal == illegal_count

	text_renderer.set_document(restore_text, restore_forbidden)
	marker_layer.clear_strokes()
	for index in range(restore_strokes.size()):
		marker_layer.strokes.append(restore_strokes[index])
		var color := marker_layer.marker_color
		if index < restore_colors.size():
			color = restore_colors[index]
		marker_layer.stroke_colors.append(color)

	return {
		"correct_illegal": correct_illegal,
		"marked_illegal": marked_illegal,
		"illegal_count": illegal_count,
		"missed_illegal": missed_illegal,
		"false_redactions": false_redactions,
		"all_illegal_marked": all_illegal_marked,
	}


func _toilet_lookup(toilet_words: Array[String]) -> Dictionary:
	var lookup := {}
	var text_renderer := _text_renderer()
	for word in toilet_words:
		lookup[text_renderer.normalize_word(word)] = true
	return lookup


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

func _try_cofefe_click(event: InputEventMouseButton) -> bool:
	var cofefe: Node2D = %Cofefe
	if not cofefe.has_method("contains_global_point"):
		return false
	if not cofefe.contains_global_point(event.global_position):
		return false
	clock.add_time(10.0)
	get_viewport().set_input_as_handled()
	return true


func _on_time_out() -> void:
	_send_to_briefing(false)
	_end_shift()


func _end_shift() -> void:
	WordManager.good_ending = WordManager.shift_correct_illegal > 0
	get_tree().change_scene_to_file("res://ending.tscn")
