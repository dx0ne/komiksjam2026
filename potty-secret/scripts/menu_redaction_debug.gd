extends Control

var target_rect := Rect2()
var tolerance := 12.0
var status_text := ""


func _draw() -> void:
	if target_rect.size == Vector2.ZERO:
		return
	var grown := target_rect.grow(tolerance)
	draw_rect(grown, Color(0.2, 1.0, 0.2, 0.12), true)
	draw_rect(grown, Color(0.1, 0.85, 0.1, 0.85), false, 1.0)
	draw_rect(target_rect, Color(1.0, 0.15, 0.15, 0.25), true)
	draw_rect(target_rect, Color(1.0, 0.0, 0.0, 0.95), false, 2.0)
	if not status_text.is_empty():
		var font := ThemeDB.fallback_font
		var pos := target_rect.position + Vector2(0.0, -22.0)
		draw_string(font, pos + Vector2(1.0, 1.0), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.BLACK)
		draw_string(font, pos, status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
