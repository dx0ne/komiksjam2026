@tool
class_name ToiletIntelLabel
extends Label

## Largest font for short intel strings (pixelization-friendly).
@export var preferred_font_size := 34:
	set(value):
		preferred_font_size = value
		_queue_fit()

## Smallest font before a uniform scale squeeze is applied.
@export var min_font_size := 22:
	set(value):
		min_font_size = value
		_queue_fit()

## Fraction of the label rect width used for fitting.
@export_range(0.5, 1.0, 0.01) var width_margin := 0.94:
	set(value):
		width_margin = value
		_queue_fit()

var _fit_pending := false


func _ready() -> void:
	_queue_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_queue_fit()


func _set(property: StringName, value: Variant) -> bool:
	if property == &"text":
		call_deferred("_queue_fit")
	return false


func set_intel_text(value: String) -> void:
	text = value
	_fit()


func _queue_fit() -> void:
	if _fit_pending:
		return
	_fit_pending = true
	call_deferred("_fit")


func _fit() -> void:
	_fit_pending = false
	if text.is_empty() or label_settings == null or label_settings.font == null:
		return

	scale = Vector2.ONE
	var settings := label_settings.duplicate()
	label_settings = settings
	var font: Font = settings.font
	var display := text.to_upper()
	text = display

	var max_w := _fit_width()
	var chosen := min_font_size
	for size in range(preferred_font_size, min_font_size - 1, -1):
		if font.get_string_size(display, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x <= max_w:
			chosen = size
			break

	settings.font_size = chosen
	var text_w := font.get_string_size(display, HORIZONTAL_ALIGNMENT_CENTER, -1, chosen).x
	if text_w > max_w:
		scale = Vector2(max_w / text_w, max_w / text_w)


func _fit_width() -> float:
	var w := size.x
	if w <= 1.0:
		w = offset_right - offset_left
	return maxf(1.0, w) * width_margin
