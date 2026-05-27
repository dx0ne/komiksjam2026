extends Control
class_name MarkerLayer

signal stroke_finished(stroke: PackedVector2Array)
signal cursor_changed

enum DrawMode { LINE, BRUSH }

const MARKER_WIDTH := 20.0
const POINT_DISTANCE := 3.0
const LINE_MIN_LENGTH := 1.0
const BLINK_FADE := 0.3
const BLINK_HALF_PERIOD := 0.33
const BLINK_PULSES := 3
const MARK_ICON_SIZE := Vector2(20.0, 20.0)
const MARK_ICON_PADDING := 2.0
const MARK_ICON_Y_OFFSET := -2.0
const MARK_TICK_PATH := "res://assets/review_accept.png"
const MARK_CROSS_PATH := "res://assets/review_cross.png"
const MARKER_CURSOR_SETTINGS_PATH := "res://assets/marker_cursor_settings.tres"
const MARKER_TEXTURE_PATH := "res://assets/Reka_Marker.png"
const MARKER_CURSOR_SCALE := Vector2(0.08, 0.08)
const MARKER_CURSOR_ROTATION := deg_to_rad(125.0)
const MARKER_CURSOR_HOTSPOT := Vector2(1655.0, 304.0)

@export var hide_os_cursor := true

var mode: DrawMode = DrawMode.BRUSH
var strokes: Array[PackedVector2Array] = []
var stroke_colors: Array[Color] = []
var current_stroke := PackedVector2Array()
var drawing := false
var locked := false
var marker_color := Color(0.0, 0.0, 0.0, 0.92)
var word_marks: Array[Dictionary] = []

var _blink_phase := 1.0
var _blink_tween: Tween
var _mark_tick_texture: Texture2D
var _mark_cross_texture: Texture2D
var _marker_texture: Texture2D
var _marker_cursor_settings
var _cursor_position := Vector2.ZERO
var _cursor_inside := false
var _owns_hidden_cursor := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mark_tick_texture = _load_pixel_texture(MARK_TICK_PATH)
	_mark_cross_texture = _load_pixel_texture(MARK_CROSS_PATH)
	_load_marker_cursor_settings()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_restore_os_cursor)

func clear_strokes() -> void:
	strokes.clear()
	stroke_colors.clear()
	current_stroke.clear()
	word_marks.clear()
	drawing = false
	_stop_blink()
	locked = false
	queue_redraw()

func apply_word_marks(marks: Array[Dictionary]) -> void:
	word_marks = marks
	queue_redraw()

func clear_word_marks() -> void:
	word_marks.clear()
	queue_redraw()

func set_locked(value: bool) -> void:
	locked = value
	if locked:
		drawing = false
		current_stroke.clear()
		_cursor_inside = false
		_restore_os_cursor()
		cursor_changed.emit()
		queue_redraw()

func set_mode(new_mode: DrawMode) -> void:
	if drawing:
		return
	mode = new_mode
	queue_redraw()

func apply_stroke_colors(colors: Array[Color]) -> void:
	stroke_colors.clear()
	for index in range(strokes.size()):
		if index < colors.size():
			stroke_colors.append(colors[index])
		else:
			stroke_colors.append(marker_color)
	_start_blink()

func clear_review() -> void:
	for index in range(stroke_colors.size()):
		stroke_colors[index] = marker_color
	_stop_blink()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor_position = event.position
		_cursor_inside = not locked
		if _cursor_inside:
			_hide_os_cursor()
		cursor_changed.emit()
		queue_redraw()
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_cursor_position = event.position
		cursor_changed.emit()
		if event.pressed:
			_start_stroke(event.position)
		else:
			_finish_stroke(event.position)
	elif event is InputEventMouseMotion:
		if drawing:
			if mode == DrawMode.LINE:
				_update_line_endpoint(event.position)
			else:
				_add_point(event.position)

func _start_stroke(point: Vector2) -> void:
	drawing = true
	if mode == DrawMode.LINE:
		current_stroke = PackedVector2Array([point, point])
	else:
		current_stroke = PackedVector2Array([point])
	queue_redraw()

func _update_line_endpoint(point: Vector2) -> void:
	if current_stroke.size() < 2:
		return
	current_stroke[1] = point
	queue_redraw()

func _add_point(point: Vector2) -> void:
	if current_stroke.is_empty() or current_stroke[current_stroke.size() - 1].distance_to(point) >= POINT_DISTANCE:
		current_stroke.append(point)
		queue_redraw()

func _finish_stroke(point: Vector2) -> void:
	if not drawing:
		return
	drawing = false
	var completed := PackedVector2Array()
	if mode == DrawMode.LINE:
		var anchor := current_stroke[0]
		if anchor.distance_to(point) < LINE_MIN_LENGTH:
			completed = PackedVector2Array([anchor])
		else:
			completed = PackedVector2Array([anchor, point])
	else:
		_add_point(point)
		if current_stroke.size() > 1:
			completed = PackedVector2Array(current_stroke)
	current_stroke.clear()
	if not completed.is_empty():
		strokes.append(completed)
		stroke_colors.append(marker_color)
		stroke_finished.emit(completed)
	queue_redraw()

func _draw() -> void:
	for index in range(strokes.size()):
		var color := stroke_colors[index] if index < stroke_colors.size() else marker_color
		_draw_stroke(strokes[index], _modulate(color))
	if drawing:
		_draw_stroke(current_stroke, marker_color)
	_draw_word_marks()

func _draw_word_marks() -> void:
	if word_marks.is_empty():
		return
	for mark in word_marks:
		var rect: Rect2 = mark["rect"]
		var kind: String = mark["kind"]
		var texture := _mark_tick_texture if kind == "tick" else _mark_cross_texture
		if texture == null:
			continue
		var pos := Vector2(
			rect.position.x + rect.size.x + MARK_ICON_PADDING,
			rect.position.y + MARK_ICON_Y_OFFSET
		)
		draw_texture_rect(texture, Rect2(pos, MARK_ICON_SIZE), false)

func _load_pixel_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource := load(path)
		if resource is Texture2D:
			return resource
	var image := Image.load_from_file(path)
	if image == null:
		push_warning("Could not load review mark texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func is_marker_cursor_visible() -> bool:
	return _cursor_inside and _marker_texture != null

func get_marker_cursor_texture() -> Texture2D:
	return _marker_texture

func get_marker_cursor_position() -> Vector2:
	return _cursor_position

func get_marker_cursor_scale() -> Vector2:
	return _marker_cursor_scale()

func get_marker_cursor_rotation() -> float:
	return _marker_cursor_rotation()

func get_marker_cursor_hotspot() -> Vector2:
	return _marker_cursor_hotspot()

func _load_marker_cursor_settings() -> void:
	if ResourceLoader.exists(MARKER_CURSOR_SETTINGS_PATH):
		var resource := load(MARKER_CURSOR_SETTINGS_PATH)
		if resource is Resource:
			_marker_cursor_settings = resource
	if _marker_cursor_settings != null:
		_marker_texture = _marker_cursor_settings.load_texture()
	if _marker_texture == null:
		_marker_texture = _load_pixel_texture(MARKER_TEXTURE_PATH)

func _marker_cursor_scale() -> Vector2:
	if _marker_cursor_settings != null:
		return _marker_cursor_settings.scale_vector()
	return MARKER_CURSOR_SCALE

func _marker_cursor_rotation() -> float:
	if _marker_cursor_settings != null:
		return _marker_cursor_settings.rotation_radians()
	return MARKER_CURSOR_ROTATION

func _marker_cursor_hotspot() -> Vector2:
	if _marker_cursor_settings != null:
		return _marker_cursor_settings.hotspot
	return MARKER_CURSOR_HOTSPOT

func _on_mouse_entered() -> void:
	if locked:
		return
	_cursor_position = get_local_mouse_position()
	_cursor_inside = true
	_hide_os_cursor()
	cursor_changed.emit()
	queue_redraw()

func _on_mouse_exited() -> void:
	_cursor_inside = false
	_restore_os_cursor()
	cursor_changed.emit()
	queue_redraw()

func _hide_os_cursor() -> void:
	if not hide_os_cursor or _owns_hidden_cursor:
		return
	_previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_owns_hidden_cursor = true

func _restore_os_cursor() -> void:
	if not hide_os_cursor or not _owns_hidden_cursor:
		return
	Input.set_mouse_mode(_previous_mouse_mode)
	_owns_hidden_cursor = false

func _draw_stroke(stroke: PackedVector2Array, color: Color) -> void:
	if stroke.size() == 1:
		var half := MARKER_WIDTH * 0.5
		draw_rect(Rect2(stroke[0] - Vector2(half, half), Vector2(MARKER_WIDTH, MARKER_WIDTH)), color)
	elif stroke.size() == 2:
		draw_line(stroke[0], stroke[1], color, MARKER_WIDTH, false)
	elif stroke.size() > 2:
		draw_polyline(stroke, color, MARKER_WIDTH, false)
		for point in stroke:
			draw_circle(point, MARKER_WIDTH * 0.5, color)

func _modulate(color: Color) -> Color:
	var alpha := color.a * lerpf(BLINK_FADE, 1.0, _blink_phase)
	return Color(color.r, color.g, color.b, alpha)

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
