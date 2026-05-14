extends Control
class_name MarkerCursorLayer

var marker_layer: MarkerLayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _exit_tree() -> void:
	_disconnect_marker_layer()

func set_marker_layer(value: MarkerLayer) -> void:
	if marker_layer == value:
		return
	_disconnect_marker_layer()
	marker_layer = value
	if marker_layer != null:
		marker_layer.cursor_changed.connect(_on_cursor_changed)
	queue_redraw()

func _draw() -> void:
	if marker_layer == null or not marker_layer.is_marker_cursor_visible():
		return

	var texture := marker_layer.get_marker_cursor_texture()
	if texture == null:
		return

	draw_set_transform(
		marker_layer.get_marker_cursor_position(),
		marker_layer.get_marker_cursor_rotation(),
		marker_layer.get_marker_cursor_scale()
	)
	draw_texture(texture, -marker_layer.get_marker_cursor_hotspot())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _disconnect_marker_layer() -> void:
	if marker_layer == null:
		return
	if marker_layer.cursor_changed.is_connected(_on_cursor_changed):
		marker_layer.cursor_changed.disconnect(_on_cursor_changed)

func _on_cursor_changed() -> void:
	queue_redraw()
