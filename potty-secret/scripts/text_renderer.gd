extends Control
class_name TextRenderer

const PAPER_INSET := 44.0
const LINE_SPACING := 12.0
const WORD_SPACING := 12.0
const BLINK_FADE := 0.35
const BLINK_HALF_PERIOD := 0.33
const BLINK_PULSES := 3
const MISSED_COLOR := Color(0.85, 0.15, 0.15)
const MISSED_ALPHA_MAX := 0.7
const TYPEWRITER_FONT_PATH := "res://fonts/Mom_typewriter.ttf"

var document_text := ""
var illegal_words: Array[String] = []
var planted_canonicals: Array[String] = []
var decoy_canonicals: Array[String] = []
var word_boxes: Array[Dictionary] = []

var _font: Font
var _font_size := 22
var _text_color := Color(0.12, 0.10, 0.08)
var _stamp_color := Color(0.50, 0.03, 0.02, 0.35)

var _blink_phase := 1.0
var _blink_tween: Tween

func _ready() -> void:
	_font = _load_typewriter_font()
	resized.connect(_relayout)

func set_document(text: String, forbidden_words: Array[String]) -> void:
	document_text = text
	illegal_words = forbidden_words
	_relayout()


func set_forbidden_words(forbidden_words: Array[String]) -> void:
	# forbidden_words is retained for API stability but is no longer the source
	# of truth for the illegal flag. Canonical matching via WordManager is used instead.
	illegal_words = forbidden_words
	for box in word_boxes:
		box["illegal"] = WordManager.canonicalize(box["word"]) in WordManager.current_toilet_canonicals
		box["redacted"] = false
		box["coverage"] = 0.0
		box["tier"] = "none"
		box["review"] = ""
	queue_redraw()


func set_planted_canonicals(canonicals: Array[String]) -> void:
	planted_canonicals.assign(canonicals)
	for box in word_boxes:
		box["planted"] = WordManager.canonicalize(box["word"]) in planted_canonicals
	queue_redraw()


func set_decoy_canonicals(canonicals: Array) -> void:
	decoy_canonicals.clear()
	for c in canonicals:
		decoy_canonicals.append(c)
	for box in word_boxes:
		box["decoy"] = WordManager.canonicalize(box["word"]) in decoy_canonicals
	queue_redraw()


func count_illegal_tokens() -> int:
	var total := 0
	for box in word_boxes:
		if box.get("illegal", false):
			total += 1
	return total

func apply_review_states(missed_indices: Array[int]) -> void:
	for index in range(word_boxes.size()):
		word_boxes[index]["review"] = ""
	for index in missed_indices:
		if index >= 0 and index < word_boxes.size():
			word_boxes[index]["review"] = "missed"
	_start_blink()

func reset_review() -> void:
	for index in range(word_boxes.size()):
		word_boxes[index]["review"] = ""
	_stop_blink()

func _relayout() -> void:
	if _font == null:
		_font = get_theme_default_font()
	word_boxes.clear()
	if document_text.is_empty() or _font == null:
		queue_redraw()
		return

	var available_width := maxf(64.0, size.x - PAPER_INSET * 2.0)
	var cursor := Vector2(PAPER_INSET, PAPER_INSET + _font_size)
	var line_height := _font.get_height(_font_size) + LINE_SPACING

	for display_word in document_text.split(" ", false):
		var word_width := _font.get_string_size(display_word, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		if cursor.x > PAPER_INSET and cursor.x + word_width > PAPER_INSET + available_width:
			cursor.x = PAPER_INSET
			cursor.y += line_height

		var normalized_word := _normalize_word(display_word)
		var word_canonical := WordManager.canonicalize(normalized_word)
		var rect := Rect2(
			Vector2(cursor.x, cursor.y - _font_size),
			Vector2(word_width, _font.get_height(_font_size))
		)
		word_boxes.append({
			"word": normalized_word,
			"display": display_word,
			"rect": rect,
			"illegal": word_canonical in WordManager.current_toilet_canonicals,
			"planted": word_canonical in planted_canonicals,
			"decoy": word_canonical in decoy_canonicals,
			"redacted": false,
			"coverage": 0.0,
			"tier": "none",
			"review": "",
		})
		cursor.x += word_width + WORD_SPACING

	queue_redraw()

func _draw() -> void:
	if _font == null:
		return

	_draw_letterhead()
	var highlight_alpha := lerpf(BLINK_FADE * MISSED_ALPHA_MAX, MISSED_ALPHA_MAX, _blink_phase)
	for box in word_boxes:
		if box.get("review", "") == "missed":
			var rect: Rect2 = box["rect"]
			draw_rect(rect.grow(3.0), Color(MISSED_COLOR.r, MISSED_COLOR.g, MISSED_COLOR.b, highlight_alpha))
		var baseline := Vector2(box["rect"].position.x, box["rect"].position.y + _font_size)
		draw_string(_font, baseline, box["display"], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _text_color)

func _draw_letterhead() -> void:
	var header_rect := Rect2(Vector2(PAPER_INSET, 18.0), Vector2(size.x - PAPER_INSET * 2.0, 4.0))
	draw_rect(header_rect, Color(0.18, 0.15, 0.11, 0.35))
	draw_string(_font, Vector2(PAPER_INSET, 36.0), "MINISTRY REVIEW COPY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _stamp_color)
	draw_string(_font, Vector2(size.x - PAPER_INSET - 160.0, 36.0), "CLASSIFIED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _stamp_color)

func normalize_word(value: String) -> String:
	return _normalize_word(value)


func _normalize_word(value: String) -> String:
	var normalized := value.to_lower()
	var output := ""
	for index in range(normalized.length()):
		var code := normalized.unicode_at(index)
		var is_letter := code >= 97 and code <= 122
		var is_number := code >= 48 and code <= 57
		if is_letter or is_number:
			output += char(code)
	return output

func _start_blink() -> void:
	_stop_blink()
	_blink_phase = 1.0
	_blink_tween = create_tween()
	for i in range(BLINK_PULSES):
		_blink_tween.tween_method(_set_blink_phase, 1.0, BLINK_FADE, BLINK_HALF_PERIOD)
		_blink_tween.tween_method(_set_blink_phase, BLINK_FADE, 1.0, BLINK_HALF_PERIOD)
	queue_redraw()

func _stop_blink() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = null
	_blink_phase = 1.0
	queue_redraw()

func _set_blink_phase(value: float) -> void:
	_blink_phase = value
	queue_redraw()

func _load_typewriter_font() -> Font:
	var resource := load(TYPEWRITER_FONT_PATH)
	if resource is Font:
		return resource
	push_warning("Could not load typewriter font: %s" % TYPEWRITER_FONT_PATH)
	return get_theme_default_font()
