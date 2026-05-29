extends Node2D

signal sip_requested
signal mug_placed(global_center: Vector2, ring_radius: float, drop_vector: Vector2, drop_speed: float)
signal drag_started
signal drag_ended

const CLICK_PADDING := Vector2(12, 12)
const DRAG_THRESHOLD := 10.0
const HOME_TWEEN_DURATION := 0.28

var _dragging := false
var _drag_offset := Vector2.ZERO
var _drag_start_global := Vector2.ZERO
var _home_position := Vector2.ZERO
var _last_drag_velocity := Vector2.ZERO
var _return_tween: Tween
@onready var _inside: Sprite2D = $Inside


func _ready() -> void:
	_home_position = position


func get_smear_ring_global() -> Dictionary:
	var rect := _inside.get_rect()
	var xf := _inside.get_global_transform_with_canvas()
	var center_global: Vector2 = xf * rect.get_center()
	var scale := xf.get_scale()
	var ring_radius: float = minf(rect.size.x * scale.x, rect.size.y * scale.y) * 0.5
	return {"center": center_global, "radius": ring_radius}


func contains_global_point(global_point: Vector2) -> bool:
	var mug: Sprite2D = $Mug
	if mug.texture == null:
		return false
	var local := mug.get_global_transform_with_canvas().affine_inverse() * global_point
	var rect := mug.get_rect().grow_individual(
		CLICK_PADDING.x,
		CLICK_PADDING.y,
		CLICK_PADDING.x,
		CLICK_PADDING.y
	)
	return rect.has_point(local)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not contains_global_point(event.global_position):
				return
			if _return_tween and _return_tween.is_valid():
				_return_tween.kill()
			_dragging = true
			_drag_offset = global_position - event.global_position
			_drag_start_global = event.global_position
			_last_drag_velocity = Vector2.ZERO
			z_index = 10
			drag_started.emit()
			get_viewport().set_input_as_handled()
		elif _dragging:
			_dragging = false
			z_index = 0
			var moved: float = event.global_position.distance_to(_drag_start_global)
			if moved < DRAG_THRESHOLD:
				sip_requested.emit()
			else:
				var drop_speed: float = _last_drag_velocity.length()
				var ring := get_smear_ring_global()
				mug_placed.emit(ring["center"], ring["radius"], _last_drag_velocity, drop_speed)
			drag_ended.emit()
			_tween_home()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and _dragging:
		global_position = event.global_position + _drag_offset
		_last_drag_velocity = event.velocity
		get_viewport().set_input_as_handled()


func _tween_home() -> void:
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	_return_tween = create_tween()
	_return_tween.tween_property(self, "position", _home_position, HOME_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
