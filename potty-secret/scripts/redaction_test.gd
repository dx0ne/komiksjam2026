extends Control

# Standalone test bed for the thick-black-bars redaction mechanic.
# Near-copy of document_scene.gd from the source project, adapted for:
#   - 1920x1080 viewport (potty-secret native resolution)
#   - No WordManager wiring (phase 2 concern)
#   - @onready paths matching this scene's node names

const REDACTION_TOLERANCE := 12.0
const SAMPLE_STEP := 6.0
const COVERAGE_CELL_WIDTH := 8.0
const COVERAGE_HALF_RATIO := 0.50
const COVERAGE_FULL_RATIO := 0.70
const COVERAGE_MIN_CELLS := 2
const APPROVAL_FRACTION := 0.75
const TYPEWRITER_FONT_PATH := "res://fonts/Mom_typewriter.ttf"

@onready var background_paper: Panel = $BackgroundPaper
@onready var text_renderer: TextRenderer = $TextRenderer
@onready var marker_layer: MarkerLayer = $MarkerLayer
@onready var marker_cursor_layer: MarkerCursorLayer = $MarkerCursorLayer
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var submit_button: Button = $UI/MarginContainer/VBoxContainer/SubmitButton
@onready var new_document_button: Button = $UI/MarginContainer/VBoxContainer/NewDocumentButton
@onready var score_label: Label = $UI/MarginContainer/VBoxContainer/ScoreLabel
@onready var timer_label: Label = $UI/MarginContainer/VBoxContainer/TimerLabel
@onready var directive_label: Label = $UI/MarginContainer/VBoxContainer/DirectiveLabel

var forbidden_pool: Array[String] = [
	"freedom",
	"radio",
	"union",
	"assembly",
	"passport",
	"printing",
	"border",
	"manifesto",
]

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

var active_forbidden_words: Array[String] = []
var rng := RandomNumberGenerator.new()
var _ui_font: Font


func _ready() -> void:
	rng.randomize()
	_ui_font = _load_typewriter_font()
	_apply_ui_font($UI)
	marker_cursor_layer.set_marker_layer(marker_layer)
	submit_button.pressed.connect(_on_submit_pressed)
	new_document_button.pressed.connect(_generate_document)
	debug_overlay.text_renderer = text_renderer
	debug_overlay.tolerance = REDACTION_TOLERANCE
	_generate_document()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			debug_overlay.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			var new_mode := MarkerLayer.DrawMode.BRUSH if marker_layer.mode == MarkerLayer.DrawMode.LINE else MarkerLayer.DrawMode.LINE
			marker_layer.set_mode(new_mode)
			_update_score_label("Marker mode: %s" % ("LINE" if new_mode == MarkerLayer.DrawMode.LINE else "BRUSH"))
			get_viewport().set_input_as_handled()


func _generate_document() -> void:
	var shuffled_pool: Array[String] = []
	shuffled_pool.assign(forbidden_pool)
	shuffled_pool.shuffle()
	active_forbidden_words.clear()
	active_forbidden_words.append(shuffled_pool[0])
	active_forbidden_words.append(shuffled_pool[1])

	var text := templates[rng.randi_range(0, templates.size() - 1)]
	text = text.replace("{name}", names[rng.randi_range(0, names.size() - 1)])
	text = text.replace("{illegal_a}", active_forbidden_words[0])
	text = text.replace("{illegal_b}", active_forbidden_words[1])
	text += " File handler must obscure all prohibited terms before forwarding to the archive desk."

	text_renderer.set_document(text, active_forbidden_words)
	marker_layer.clear_strokes()
	text_renderer.reset_review()
	marker_layer.set_locked(false)
	debug_overlay.clear_stroke_samples()
	_update_directive()
	_update_score_label("Drag the marker over forbidden words, then submit.")


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


func _on_submit_pressed() -> void:
	var all_samples: Array[PackedVector2Array] = []
	for stroke in marker_layer.strokes:
		all_samples.append(_sample_stroke(stroke))

	var word_marks: Array[Dictionary] = []
	var missed_indices: Array[int] = []
	var score := 0.0
	var fully := 0
	var halfly := 0
	var missed := 0
	var false_redactions := 0
	var illegal_count := 0

	for index in range(text_renderer.word_boxes.size()):
		var box := text_renderer.word_boxes[index]
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
		box["coverage"] = float(touched.size()) / float(cell_total)
		box["tier"] = tier
		box["redacted"] = tier != "none"

		if box["illegal"]:
			illegal_count += 1
			match tier:
				"full":
					score += 2.0
					fully += 1
					word_marks.append({"rect": box["rect"], "kind": "tick"})
				"half":
					score += 1.0
					halfly += 1
					word_marks.append({"rect": box["rect"], "kind": "tick"})
				_:
					score -= 1.0
					missed += 1
					missed_indices.append(index)
					word_marks.append({"rect": box["rect"], "kind": "cross"})
		else:
			match tier:
				"full":
					score -= 0.5
					false_redactions += 1
					word_marks.append({"rect": box["rect"], "kind": "cross"})
				"half":
					score -= 0.25
					false_redactions += 1
					word_marks.append({"rect": box["rect"], "kind": "cross"})

	var max_score := float(illegal_count) * 2.0
	var verdict := "APPROVED" if score >= max_score * APPROVAL_FRACTION else "REVIEW FAILED"

	_update_score_label(
		"%s\nScore: %s / %s\nFull: %d  Half: %d  Missed: %d\nFalse: %d" % [
			verdict,
			_format_score(score),
			_format_score(max_score),
			fully,
			halfly,
			missed,
			false_redactions,
		]
	)

	debug_overlay.set_stroke_samples(all_samples)
	marker_layer.apply_word_marks(word_marks)
	text_renderer.apply_review_states(missed_indices)
	marker_layer.set_locked(true)


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


func _update_directive() -> void:
	directive_label.text = "Directive\nRedact these terms:\n• %s\n• %s" % [
		active_forbidden_words[0].to_upper(),
		active_forbidden_words[1].to_upper(),
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
