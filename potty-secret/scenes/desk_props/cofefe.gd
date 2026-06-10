extends Node2D

const ScorePopupScene := preload("res://scenes/gameplay/score_popup.tscn")
const SIPS_POPUP_OFFSET := Vector2(38.0, -58.0)
const SIPS_POPUP_FONT_SIZE := 32
const SIPS_POPUP_COLOR := Color(0.15, 0.12, 0.1, 0.9)

signal sip_requested
signal mug_placed(global_center: Vector2, ring_radius: float, drop_vector: Vector2, drop_speed: float)
signal drag_started
signal drag_ended

const MAX_SIPS := 1
const CLICK_PADDING := Vector2(12, 12)
const DRAG_THRESHOLD := 10.0
const HOME_TWEEN_DURATION := 0.28
const SIP_TWEEN_DURATION := 0.24
const INSIDE_POS_START := Vector2(42.0, -40.0)
const INSIDE_POS_END := Vector2(41.0, -4.0)
const INSIDE_SCALE_START := Vector2.ONE
const INSIDE_SCALE_END := Vector2(0.805, 0.805)

var _dragging := false
var _drag_offset := Vector2.ZERO
var _drag_start_global := Vector2.ZERO
var _home_position := Vector2.ZERO
var _last_drag_velocity := Vector2.ZERO
var _return_tween: Tween
var _home_index := -1
var _sips_used := 0
var _inside_tween: Tween
@onready var _inside: Sprite2D = $Inside


func _ready() -> void:
	_home_position = position
	reset_for_shift()


func reset_for_shift() -> void:
	_sips_used = 0
	_inside.visible = true
	_inside.modulate.a = 1.0
	_apply_inside_step(0, 0.0)


func get_sips_remaining() -> int:
	return MAX_SIPS - _sips_used


func can_sip() -> bool:
	return _sips_used < MAX_SIPS


func consume_sip() -> bool:
	if not can_sip():
		return false
	_sips_used += 1
	_apply_inside_step(_sips_used, SIP_TWEEN_DURATION)
	_spawn_sips_popup()
	AudioManager.play_sfx("coffee_sip")
	return true


func _apply_inside_step(step: int, duration: float) -> void:
	if step <= 0:
		_inside.visible = true
		_inside.modulate.a = 1.0
	if step >= MAX_SIPS:
		_tween_inside_to_end_then_hide(duration)
		return
	_inside.visible = true
	var t := clampf(float(step) / float(MAX_SIPS), 0.0, 1.0)
	var target_pos := INSIDE_POS_START.lerp(INSIDE_POS_END, t)
	var target_scale := INSIDE_SCALE_START.lerp(INSIDE_SCALE_END, t)
	_tween_inside_to(target_pos, target_scale, duration)


func _tween_inside_to_end_then_hide(duration: float) -> void:
	_tween_inside_to(INSIDE_POS_END, INSIDE_SCALE_END, duration)
	if duration <= 0.0:
		_hide_inside()
		return
	_inside_tween.finished.connect(_hide_inside, CONNECT_ONE_SHOT)


func _tween_inside_to(target_pos: Vector2, target_scale: Vector2, duration: float) -> void:
	if _inside_tween and _inside_tween.is_valid():
		_inside_tween.kill()
	if duration <= 0.0:
		_inside.position = target_pos
		_inside.scale = target_scale
		return
	_inside_tween = create_tween()
	_inside_tween.set_parallel(true)
	_inside_tween.tween_property(_inside, "position", target_pos, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_inside_tween.tween_property(_inside, "scale", target_scale, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_inside() -> void:
	_inside.visible = false


func _spawn_sips_popup() -> void:
	var left := get_sips_remaining()
	var popup: ScorePopup = ScorePopupScene.instantiate()
	add_child(popup)
	popup.position = SIPS_POPUP_OFFSET
	popup.show_delta("%d/%d" % [left, MAX_SIPS], SIPS_POPUP_COLOR, SIPS_POPUP_FONT_SIZE)


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
			_raise_for_drag()
			drag_started.emit()
			get_viewport().set_input_as_handled()
		elif _dragging:
			_dragging = false
			_restore_draw_order()
			var moved: float = event.global_position.distance_to(_drag_start_global)
			if moved < DRAG_THRESHOLD:
				if can_sip():
					sip_requested.emit()
				_tween_home(false)
			else:
				var drop_speed: float = _last_drag_velocity.length()
				var ring := get_smear_ring_global()
				mug_placed.emit(ring["center"], ring["radius"], _last_drag_velocity, drop_speed)
				_tween_home(true)
			drag_ended.emit()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and _dragging:
		global_position = event.global_position + _drag_offset
		_last_drag_velocity = event.velocity
		get_viewport().set_input_as_handled()


func _tween_home(play_set_down: bool) -> void:
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	_return_tween = create_tween()
	_return_tween.tween_property(self, "position", _home_position, HOME_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if play_set_down:
		_return_tween.finished.connect(func() -> void: AudioManager.play_sfx("mug_set_down"), CONNECT_ONE_SHOT)


func _raise_for_drag() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	_home_index = get_index()
	parent_node.move_child(self, parent_node.get_child_count() - 1)


func _restore_draw_order() -> void:
	if _home_index < 0:
		return
	var parent_node := get_parent()
	if parent_node == null:
		_home_index = -1
		return
	parent_node.move_child(self, mini(_home_index, parent_node.get_child_count() - 1))
	_home_index = -1
