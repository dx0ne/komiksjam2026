extends Node2D

# Phase 2 — game2.gd
# Boot, document generation, toilet-handle batch wiring,
# submit / next-document logic, and SPACE / M shortcuts (task-03).

const REDACTION_TOLERANCE  := 12.0
const SAMPLE_STEP          := 6.0
const COVERAGE_CELL_WIDTH  := 8.0
const COVERAGE_HALF_RATIO  := 0.50
const COVERAGE_FULL_RATIO  := 0.70
const COVERAGE_MIN_CELLS   := 2
const APPROVAL_FRACTION    := 0.75
const TYPEWRITER_FONT_PATH := "res://fonts/Mom_typewriter.ttf"

const TOILET_SCN := preload("res://toilet_msg.tscn")

@onready var background_paper:      Panel             = $BackgroundPaper
@onready var text_renderer:         TextRenderer      = $TextRenderer
@onready var marker_layer:          MarkerLayer       = $MarkerLayer
@onready var marker_cursor_layer:   MarkerCursorLayer = $MarkerCursorLayer
@onready var debug_overlay:         DebugOverlay      = $DebugOverlay
@onready var title_label:           Label             = $UI/MarginContainer/VBoxContainer/TitleLabel
@onready var directive_label:       Label             = $UI/MarginContainer/VBoxContainer/DirectiveLabel
@onready var timer_label:           Label             = $UI/MarginContainer/VBoxContainer/TimerLabel
@onready var score_label:           Label             = $UI/MarginContainer/VBoxContainer/ScoreLabel
@onready var submit_button:         Button            = $UI/MarginContainer/VBoxContainer/SubmitButton
@onready var new_document_button:   Button            = $UI/MarginContainer/VBoxContainer/NewDocumentButton

var viewport_size: Vector2
var rng := RandomNumberGenerator.new()
var _ui_font: Font

# Session-scoped list of per-paper pass/fail results.
# Populated by _on_submit_pressed; reset only on _ready (full session reset).
var paper_results: Array[bool] = []

var templates: Array[String] = [
	"Citizen {name} discussed {illegal_a} activity near the western tram depot. Witnesses also reported possession of {illegal_b} material.",
	"Report mentions {illegal_a} literature distribution by subject {name}. Secondary notes reference unauthorized {illegal_b} gathering after curfew.",
	"Subject {name} attended a private lecture concerning {illegal_a}. The lecture minutes include repeated praise for {illegal_b} and public dissent.",
	"Inspection of apartment assigned to {name} discovered correspondence about {illegal_a}. Clerk annotation suggests possible {illegal_b} coordination.",
]

var names: Array[String] = [
	"Anya Volkov",
	"Marek Orlov",
	"Elena Voss",
	"Tomas Ilyin",
	"Kira Novak",
]


func _ready() -> void:
	rng.randomize()
	viewport_size = get_viewport().get_visible_rect().size

	# Typewriter font
	_ui_font = _load_typewriter_font()
	_apply_ui_font($UI)

	# Wire redaction stack
	marker_cursor_layer.set_marker_layer(marker_layer)
	debug_overlay.text_renderer = text_renderer
	debug_overlay.tolerance = REDACTION_TOLERANCE

	# Connect gimme_toilet_btn (toilet handle — pulls new batch)
	%gimme_toilet_btn.gui_input.connect(_on_gimme_toilet_btn_gui_input)

	# Connect clock time_out — handler stubbed; verdict is phase 3
	%clock.time_out.connect(_on_time_out)

	# Connect submit and new-document buttons
	submit_button.pressed.connect(_on_submit_pressed)
	new_document_button.pressed.connect(_generate_document)

	# Connect gimme_toilet_btn2 — briefcase trigger; no-op stub for phase 2
	$gimme_toilet_btn2.gui_input.connect(_on_gimme_toilet_btn2_gui_input)

	# Populate the first batch of toilet messages, which sets
	# WordManager.current_toilet_words, then generate the first document.
	new_tolilet_msgs()
	# Note: new_tolilet_msgs calls _generate_document at its end.

	# Set initial button state after the first document is generated.
	# Override whatever _generate_document just set to ensure correctness.
	submit_button.disabled = false
	new_document_button.disabled = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("rand_toilet_msg"):
		new_tolilet_msgs()
	if event.is_action_pressed("rand_document"):
		_generate_document()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			debug_overlay.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			var new_mode := MarkerLayer.DrawMode.BRUSH \
				if marker_layer.mode == MarkerLayer.DrawMode.LINE \
				else MarkerLayer.DrawMode.LINE
			marker_layer.set_mode(new_mode)
			_update_score_label("Marker mode: %s" % (
				"LINE" if new_mode == MarkerLayer.DrawMode.LINE else "BRUSH"
			))
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Toilet-handle wiring
# ---------------------------------------------------------------------------

func _on_gimme_toilet_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toilet_pull()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toilet_pull()


func toilet_pull() -> void:
	var original_pos := Vector2(0, 0)
	var offset_pos   := original_pos + Vector2(0, 100)
	var trans_time   := 0.2

	var tween := create_tween()
	tween.tween_property(%toilet_handle, "position", offset_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(%toilet_handle, "position", original_pos, trans_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(new_tolilet_msgs)


func new_tolilet_msgs() -> void:
	# Clear previous messages
	for child in %toilet_msgs_container.get_children():
		child.queue_free()

	var max_msgs  := 3
	var y_pad_perct := 0.2
	var y_padding := viewport_size.y * y_pad_perct
	var y_spacer  := (viewport_size.y * (1.0 - y_pad_perct) * 0.8) / max_msgs

	var words := WordManager.get_next_batch(max_msgs)
	WordManager.current_toilet_words = words

	for i in range(max_msgs):
		var toilet_msg = TOILET_SCN.instantiate()
		%toilet_msgs_container.add_child(toilet_msg)
		toilet_msg.position.y = -100
		toilet_msg.set_label(words[i])
		toilet_msg.prep_tween()

		var tween := create_tween().set_parallel(true)
		var target_x := randf_range(-50, 50)
		var target_y := y_padding + (y_spacer * i)
		target_y += randf_range(-1 * y_padding * 0.1, y_padding * 0.1)
		tween.tween_property(toilet_msg, "position:y", target_y, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(toilet_msg, "position:x", target_x, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	_generate_document()


# ---------------------------------------------------------------------------
# Document generation
# ---------------------------------------------------------------------------

func _generate_document() -> void:
	# Pull the illegal words from WordManager.  Fall back to master_list if
	# current_toilet_words is empty (e.g. called before first toilet pull).
	var source: Array[String] = WordManager.current_toilet_words
	if source.size() < 2:
		source = WordManager.master_list

	var illegal_words: Array[String] = [source[0], source[1]]

	var text := templates[rng.randi_range(0, templates.size() - 1)]
	text = text.replace("{name}",      names[rng.randi_range(0, names.size() - 1)])
	text = text.replace("{illegal_a}", illegal_words[0])
	text = text.replace("{illegal_b}", illegal_words[1])
	text += " File handler must obscure all prohibited terms before forwarding to the archive desk."

	text_renderer.set_document(text, illegal_words)
	marker_layer.clear_strokes()
	text_renderer.reset_review()
	marker_layer.set_locked(false)
	debug_overlay.clear_stroke_samples()
	_update_directive()
	_update_score_label("Drag the marker over forbidden words, then submit.")

	# A fresh document is ready — player must submit before advancing.
	submit_button.disabled = false
	new_document_button.disabled = true


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _update_directive() -> void:
	var words: Array[String] = WordManager.current_toilet_words
	if words.size() < 2:
		words = WordManager.master_list
	directive_label.text = "Directive\nRedact these terms:\n• %s\n• %s" % [
		words[0].to_upper(),
		words[1].to_upper(),
	]
	timer_label.text = "Shift clock: 08:00"


func _update_score_label(message: String) -> void:
	score_label.text = message


func _load_typewriter_font() -> Font:
	var resource := load(TYPEWRITER_FONT_PATH)
	if resource is Font:
		return resource
	push_warning("Could not load typewriter font: %s" % TYPEWRITER_FONT_PATH)
	return null


func _apply_ui_font(node: Node) -> void:
	if _ui_font == null:
		return
	if node is Control:
		node.add_theme_font_override("font", _ui_font)
	if node is Button:
		node.add_theme_font_size_override("font_size", 18)
	elif node is Label:
		node.add_theme_font_size_override("font_size", 18)
		if node.name == "TitleLabel":
			node.add_theme_font_size_override("font_size", 22)
	for child in node.get_children():
		_apply_ui_font(child)


# ---------------------------------------------------------------------------
# Submit / scoring (ported from redaction_test.gd — task-03)
# ---------------------------------------------------------------------------

func _sample_stroke(stroke: PackedVector2Array) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for index in range(stroke.size() - 1):
		var start := stroke[index]
		var end   := stroke[index + 1]
		var distance    := start.distance_to(end)
		var sample_count := maxi(1, ceili(distance / SAMPLE_STEP))
		for sample_index in range(sample_count + 1):
			samples.append(start.lerp(end, float(sample_index) / float(sample_count)))
	return samples


func _on_submit_pressed() -> void:
	var all_samples: Array[PackedVector2Array] = []
	for stroke in marker_layer.strokes:
		all_samples.append(_sample_stroke(stroke))

	var word_marks: Array[Dictionary] = []
	var missed_indices: Array[int]    = []
	var score            := 0.0
	var fully            := 0
	var halfly           := 0
	var missed           := 0
	var false_redactions := 0
	var illegal_count    := 0

	for index in range(text_renderer.word_boxes.size()):
		var box   := text_renderer.word_boxes[index]
		var grown: Rect2 = box["rect"].grow(REDACTION_TOLERANCE)
		var cell_total := maxi(1, ceili(grown.size.x / COVERAGE_CELL_WIDTH))
		var touched    := {}

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
		box["coverage"] = float(touched.size()) / float(cell_total)
		box["tier"]     = tier
		box["redacted"] = tier != "none"

		if box["illegal"]:
			illegal_count += 1
			match tier:
				"full":
					score  += 2.0
					fully  += 1
					word_marks.append({"rect": box["rect"], "kind": "tick"})
				"half":
					score  += 1.0
					halfly += 1
					word_marks.append({"rect": box["rect"], "kind": "tick"})
				_:
					score  -= 1.0
					missed += 1
					missed_indices.append(index)
					word_marks.append({"rect": box["rect"], "kind": "cross"})
		else:
			match tier:
				"full":
					score            -= 0.5
					false_redactions += 1
					word_marks.append({"rect": box["rect"], "kind": "cross"})
				"half":
					score            -= 0.25
					false_redactions += 1
					word_marks.append({"rect": box["rect"], "kind": "cross"})

	var max_score := float(illegal_count) * 2.0
	var passed    := score >= max_score * APPROVAL_FRACTION
	var verdict   := "APPROVED" if passed else "REVIEW FAILED"

	# Record this paper's result in the session list.
	paper_results.append(passed)

	_update_score_label(
		"%s\nScore: %s / %s\nFull: %d  Half: %d  Missed: %d\nFalse: %d\nPapers reviewed: %d · passed: %d" % [
			verdict,
			_format_score(score),
			_format_score(max_score),
			fully,
			halfly,
			missed,
			false_redactions,
			paper_results.size(),
			paper_results.count(true),
		]
	)

	debug_overlay.set_stroke_samples(all_samples)
	marker_layer.apply_word_marks(word_marks)
	text_renderer.apply_review_states(missed_indices)
	marker_layer.set_locked(true)

	# Paper submitted — allow advancing to the next document.
	submit_button.disabled = true
	new_document_button.disabled = false
	# No scene change — verdict is phase 3.


func _coverage_tier(touched: int, total: int) -> String:
	if touched < COVERAGE_MIN_CELLS:
		return "none"
	var ratio := float(touched) / float(total)
	if ratio >= COVERAGE_FULL_RATIO:
		return "full"
	if ratio >= COVERAGE_HALF_RATIO:
		return "half"
	return "none"


func _format_score(value: float) -> String:
	if absf(value - roundf(value)) < 0.001:
		return "%d" % int(roundf(value))
	return "%.2f" % value


# ---------------------------------------------------------------------------
# gimme_toilet_btn2 — briefcase trigger (no-op stub for phase 2)
# ---------------------------------------------------------------------------

func _on_gimme_toilet_btn2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[game2] end-game trigger (gimme_toilet_btn2) — deferred to phase 3")


# ---------------------------------------------------------------------------
# Stubs
# ---------------------------------------------------------------------------

func _on_time_out() -> void:
	# Verdict / scene-change is phase 3.
	print("[game2] time_out signal received — verdict deferred to phase 3")
