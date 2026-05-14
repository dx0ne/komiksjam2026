extends Control
class_name DebugOverlay

const RECT_COLOR_LEGAL := Color(0.30, 0.55, 1.00, 0.85)
const RECT_COLOR_ILLEGAL := Color(1.00, 0.35, 0.35, 0.95)
const RECT_COLOR_REDACTED := Color(0.30, 0.95, 0.40, 0.90)
const TOLERANCE_COLOR := Color(1.00, 0.95, 0.20, 0.55)
const SAMPLE_COLOR := Color(1.00, 0.20, 1.00, 0.95)
const SAMPLE_RADIUS := 2.0
const RECT_LINE_WIDTH := 1.0
const TOLERANCE_LINE_WIDTH := 1.0

var enabled := false
var tolerance := 0.0
var text_renderer: TextRenderer
var stroke_samples: Array[PackedVector2Array] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	queue_redraw()

func toggle() -> void:
	set_enabled(not enabled)

func set_stroke_samples(samples: Array[PackedVector2Array]) -> void:
	stroke_samples = samples
	queue_redraw()

func clear_stroke_samples() -> void:
	stroke_samples.clear()
	queue_redraw()

func _draw() -> void:
	if not enabled or text_renderer == null:
		return
	for box in text_renderer.word_boxes:
		var rect: Rect2 = box["rect"]
		draw_rect(rect.grow(tolerance), TOLERANCE_COLOR, false, TOLERANCE_LINE_WIDTH)
		var rect_color := RECT_COLOR_LEGAL
		if box.get("redacted", false):
			rect_color = RECT_COLOR_REDACTED
		elif box.get("illegal", false):
			rect_color = RECT_COLOR_ILLEGAL
		draw_rect(rect, rect_color, false, RECT_LINE_WIDTH)
	for samples in stroke_samples:
		for point in samples:
			draw_circle(point, SAMPLE_RADIUS, SAMPLE_COLOR)
