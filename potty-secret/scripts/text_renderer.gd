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
## Onboarding "mark here" pulse — warm amber, kept distinct from the red missed-word highlight.
const HINT_COLOR := Color(0.95, 0.65, 0.15)
const HINT_ALPHA_MAX := 0.55
## Onboarding ghost swipe demo — translucent marker stroke that animates across the target word.
const DEMO_SWIPE_COLOR := Color(0.0, 0.0, 0.0, 0.28)
const DEMO_SWIPE_WIDTH := 18.0
const DEMO_SWIPE_DRAW_S := 1.1
const DEMO_SWIPE_GAP_S := 0.5
const TYPEWRITER_FONT_PATH := "res://fonts/Mom_typewriter.ttf"

var document_text := ""
var illegal_words: Array[String] = []
var planted_canonicals: Array[String] = []
var decoy_canonicals: Array[String] = []
var word_boxes: Array[Dictionary] = []
var show_letterhead := true
var _transparent_words: Array[String] = []

var _font: Font
var _font_size := 22
var _text_color := Color(0.12, 0.10, 0.08)
var _stamp_color := Color(0.50, 0.03, 0.02, 0.35)

var _blink_phase := 1.0
var _blink_tween: Tween

var _hint_index := -1
var _hint_phase := 1.0
var _hint_tween: Tween

var _demo_index := -1
var _demo_t := 0.0
var _demo_tween: Tween

func _ready() -> void:
	_font = _load_typewriter_font()
	resized.connect(_relayout)

func set_document(text: String, forbidden_words: Array[String]) -> void:
	document_text = text
	illegal_words = forbidden_words
	clear_hint()
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
		box["planted"] = _token_is_planted(
			WordManager.canonicalize(str(box.get("display", ""))),
			str(box.get("display", ""))
		)
	queue_redraw()


func set_decoy_canonicals(canonicals: Array) -> void:
	decoy_canonicals.clear()
	for c in canonicals:
		decoy_canonicals.append(c)
	for box in word_boxes:
		box["decoy"] = WordManager.canonicalize(box["word"]) in decoy_canonicals
	queue_redraw()


## Tutorial / topic-intro targets: drawn invisible until the player redacts them.
func set_transparent_words(words: Array) -> void:
	_transparent_words.clear()
	for w in words:
		_transparent_words.append(_normalize_word(str(w)))
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


## Onboarding: pulse a "mark here" highlight on the word box at `index` (-1 to clear).
func set_hint_word(index: int) -> void:
	if index == _hint_index:
		return
	_hint_index = index
	if _hint_index >= 0:
		_start_hint_blink()
	else:
		_stop_hint_blink()


## Onboarding: clear both the pulse and the ghost swipe demo.
func clear_hint() -> void:
	set_hint_word(-1)
	stop_demo_swipe()


## Onboarding: loop a translucent marker swipe across the word box at `index`.
func play_demo_swipe(index: int) -> void:
	if index < 0 or index >= word_boxes.size():
		return
	_demo_index = index
	_stop_demo_tween()
	_demo_t = 0.0
	_demo_tween = create_tween().set_loops()
	_demo_tween.tween_method(_set_demo_t, 0.0, 1.0, DEMO_SWIPE_DRAW_S) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_demo_tween.tween_interval(DEMO_SWIPE_GAP_S)
	_demo_tween.tween_callback(_set_demo_t.bind(0.0))
	queue_redraw()


func stop_demo_swipe() -> void:
	_demo_index = -1
	_stop_demo_tween()
	queue_redraw()


func _stop_demo_tween() -> void:
	if _demo_tween and _demo_tween.is_valid():
		_demo_tween.kill()
	_demo_tween = null


func _set_demo_t(value: float) -> void:
	_demo_t = value
	queue_redraw()


func _start_hint_blink() -> void:
	_stop_hint_blink()
	_hint_phase = 1.0
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_method(_set_hint_phase, 1.0, BLINK_FADE, BLINK_HALF_PERIOD)
	_hint_tween.tween_method(_set_hint_phase, BLINK_FADE, 1.0, BLINK_HALF_PERIOD)
	queue_redraw()


func _stop_hint_blink() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null
	_hint_phase = 1.0
	queue_redraw()


func _set_hint_phase(value: float) -> void:
	_hint_phase = value
	queue_redraw()

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

	var normalized := document_text.replace("\r\n", "\n").replace("\r", "\n")
	var lines := normalized.split("\n")
	var first_line := true
	for line in lines:
		if not first_line:
			cursor.x = PAPER_INSET
			cursor.y += line_height
		first_line = false
		cursor = _layout_line(line, cursor, available_width, line_height)

	queue_redraw()

func _draw() -> void:
	if _font == null:
		return

	_draw_letterhead()
	var highlight_alpha := lerpf(BLINK_FADE * MISSED_ALPHA_MAX, MISSED_ALPHA_MAX, _blink_phase)
	var hint_alpha := lerpf(BLINK_FADE * HINT_ALPHA_MAX, HINT_ALPHA_MAX, _hint_phase)
	for index in range(word_boxes.size()):
		var box := word_boxes[index]
		var rect: Rect2 = box["rect"]
		if box.get("review", "") == "missed":
			draw_rect(rect.grow(3.0), Color(MISSED_COLOR.r, MISSED_COLOR.g, MISSED_COLOR.b, highlight_alpha))
		elif index == _hint_index:
			draw_rect(rect.grow(3.0), Color(HINT_COLOR.r, HINT_COLOR.g, HINT_COLOR.b, hint_alpha))
		var baseline := Vector2(rect.position.x, rect.position.y + _font_size)
		var ink := _text_color
		if _is_transparent_target(box):
			ink.a = 0.0
		draw_string(_font, baseline, box["display"], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, ink)

	_draw_demo_swipe()

func _draw_demo_swipe() -> void:
	if _demo_index < 0 or _demo_index >= word_boxes.size():
		return
	var rect: Rect2 = word_boxes[_demo_index]["rect"]
	var y := rect.position.y + rect.size.y * 0.5
	var x0 := rect.position.x - 4.0
	var x1 := rect.position.x + rect.size.x + 4.0
	var head := lerpf(x0, x1, clampf(_demo_t, 0.0, 1.0))
	if head <= x0:
		return
	draw_line(Vector2(x0, y), Vector2(head, y), DEMO_SWIPE_COLOR, DEMO_SWIPE_WIDTH, true)
	draw_circle(Vector2(head, y), DEMO_SWIPE_WIDTH * 0.5, DEMO_SWIPE_COLOR)

func _is_transparent_target(box: Dictionary) -> bool:
	if _transparent_words.is_empty():
		return false
	return box.get("word", "") in _transparent_words

func _draw_letterhead() -> void:
	if not show_letterhead:
		return
	var header_rect := Rect2(Vector2(PAPER_INSET, 18.0), Vector2(size.x - PAPER_INSET * 2.0, 4.0))
	draw_rect(header_rect, Color(0.18, 0.15, 0.11, 0.35))
	draw_string(_font, Vector2(PAPER_INSET, 36.0), "MINISTRY REVIEW COPY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _stamp_color)
	draw_string(_font, Vector2(size.x - PAPER_INSET - 160.0, 36.0), "CLASSIFIED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _stamp_color)

func normalize_word(value: String) -> String:
	return _normalize_word(value)


func _layout_line(line: String, cursor: Vector2, available_width: float, line_height: float) -> Vector2:
	var tokens := _tokenize_line(line)
	if tokens.is_empty():
		return cursor

	# Longest-match N-gram pass so multi-word canonicals (e.g. "the Grays",
	# "Project Blue Book") become a single markable box. N_MAX = 3 covers
	# the longest entries in WordManager.master_list (3-word canonicals and
	# 3-word synonyms like "the goat sucker").
	var i := 0
	while i < tokens.size():
		var matched_n := 1
		var matched_display: String = tokens[i]
		var matched_canonical := WordManager.canonicalize(tokens[i])
		for n in [3, 2]:
			if i + n > tokens.size():
				continue
			var candidate: String = " ".join(tokens.slice(i, i + n))
			var c := WordManager.canonicalize(candidate)
			if c != "":
				matched_n = n
				matched_display = candidate
				matched_canonical = c
				break

		var word_width := _font.get_string_size(matched_display, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		if cursor.x > PAPER_INSET and cursor.x + word_width > PAPER_INSET + available_width:
			cursor.x = PAPER_INSET
			cursor.y += line_height

		var rect := Rect2(
			Vector2(cursor.x, cursor.y - _font_size),
			Vector2(word_width, _font.get_height(_font_size))
		)
		word_boxes.append({
			"word": _normalize_word(matched_display),
			"display": matched_display,
			"rect": rect,
			"illegal": matched_canonical != "" and matched_canonical in WordManager.current_toilet_canonicals,
			"planted": _token_is_planted(matched_canonical, matched_display),
			"decoy": matched_canonical != "" and matched_canonical in decoy_canonicals,
			"redacted": false,
			"coverage": 0.0,
			"tier": "none",
			"review": "",
		})
		cursor.x += word_width + WORD_SPACING
		i += matched_n
	return cursor


func _tokenize_line(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var current := ""
	for i in range(text.length()):
		var code := text.unicode_at(i)
		var is_space := code == 32 or code == 9
		if is_space:
			if not current.is_empty():
				tokens.append(current)
				current = ""
		else:
			current += char(code)
	if not current.is_empty():
		tokens.append(current)
	return tokens


func _token_is_planted(matched_canonical: String, matched_display: String) -> bool:
	if planted_canonicals.is_empty():
		return false
	var norm := _normalize_word(matched_display)
	for planted in planted_canonicals:
		if WordManager._normalize(planted) == norm:
			return true
		if not matched_canonical.is_empty() and matched_canonical == planted:
			return true
	return false


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
