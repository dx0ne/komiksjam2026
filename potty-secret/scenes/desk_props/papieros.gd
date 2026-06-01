extends Node2D

signal puff_requested
signal burned_out

enum State { UNLIT, BURNING, STUB }

const CLICK_PADDING := Vector2(10, 10)
const BURN_DURATION := 34.0
const PLACE_ON_ASHTRAY_DURATION := 0.38
## Left portion of texture width kept when fully burned (filter / stub).
const STUB_WIDTH_RATIO := 0.26
## `Papieros_used` root minus %popielniczka position (sibling space).
const ASHTRAY_OFFSET_FROM_POP := Vector2(28.0001, 41.00007)
const ASHTRAY_BASE_ROTATION := 3.8013272
const ROTATION_PER_PUFF := 0.11
const PUFF_ROTATE_DURATION := 0.14
## Drop-shadow nudge in body-local space (tuned for desk rotation).
const SHADOW_OFFSET := Vector2(-12.41, 11.645)

@onready var _body: Sprite2D = $Body
@onready var _cien: Sprite2D = $PapierosCien
@onready var _smoke: GPUParticles2D = $Smoke/papieros_smoke

var _state := State.UNLIT
var _burn_tween: Tween
var _place_tween: Tween
var _puff_tween: Tween
var _texture_size := Vector2.ZERO
var _desk_position := Vector2.ZERO
var _desk_rotation := 0.0
var _puff_count := 0
var _ashtray: Node2D


func _ready() -> void:
	_desk_position = position
	_desk_rotation = rotation
	if _body.texture:
		_texture_size = _body.texture.get_size()
		_body.region_enabled = true
		_body.centered = false
		_body.offset = Vector2(0.0, -_texture_size.y * 0.5)
		_cien.centered = false
		_cien.offset = _body.offset
	_apply_length_ratio(1.0)
	_set_smoke(false)


func bind_ashtray(ashtray: Node2D) -> void:
	_ashtray = ashtray


func reset_for_shift() -> void:
	_stop_burn()
	_stop_place_tween()
	_stop_puff_tween()
	_puff_count = 0
	_state = State.UNLIT
	_apply_length_ratio(1.0)
	_set_smoke(false)
	_body.modulate = Color.WHITE
	position = _desk_position
	rotation = _desk_rotation


func can_puff() -> bool:
	return _state == State.UNLIT or _state == State.BURNING


func contains_global_point(global_point: Vector2) -> bool:
	if _body.texture == null or not visible:
		return false
	var local := _body.get_global_transform_with_canvas().affine_inverse() * global_point
	var rect := _body.get_rect().grow_individual(
		CLICK_PADDING.x,
		CLICK_PADDING.y,
		CLICK_PADDING.x,
		CLICK_PADDING.y
	)
	return rect.has_point(local)


func _input(event: InputEvent) -> void:
	if not visible or not can_puff():
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and contains_global_point(event.global_position):
		_apply_puff_click()
		puff_requested.emit()
		get_viewport().set_input_as_handled()


func _apply_puff_click() -> void:
	_puff_count += 1
	var target_rot := _ashtray_rotation_for_puff(_puff_count)
	var target_pos := _ashtray_position(target_rot)
	if _state == State.UNLIT:
		_state = State.BURNING
		_place_on_ashtray(target_pos, target_rot)
	else:
		_tween_puff_pose(target_pos, target_rot)


func _ashtray_rotation_for_puff(puff_index: int) -> float:
	var offset := 0.0
	for step in range(1, puff_index):
		offset += ROTATION_PER_PUFF if step % 2 == 1 else -ROTATION_PER_PUFF
	return ASHTRAY_BASE_ROTATION + offset


func _ashtray_position(rot: float) -> Vector2:
	var marker_root := _ashtray.position + ASHTRAY_OFFSET_FROM_POP if _ashtray else Vector2(1578.0001, 58.00007)
	if _texture_size == Vector2.ZERO:
		return marker_root
	# Editor marker used centered body; we anchor the filter end at the node origin.
	return marker_root - Vector2(_texture_size.x * 0.5, 0.0).rotated(rot)


func _place_on_ashtray(target_pos: Vector2, target_rot: float) -> void:
	_stop_place_tween()
	_stop_puff_tween()
	_place_tween = create_tween()
	_place_tween.tween_property(self, "position", target_pos, PLACE_ON_ASHTRAY_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_place_tween.parallel().tween_property(self, "rotation", target_rot, PLACE_ON_ASHTRAY_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_place_tween.tween_callback(_begin_burn_on_ashtray)


func _tween_puff_pose(target_pos: Vector2, target_rot: float) -> void:
	_stop_puff_tween()
	_puff_tween = create_tween()
	_puff_tween.set_parallel(true)
	_puff_tween.tween_property(self, "position", target_pos, PUFF_ROTATE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_puff_tween.tween_property(self, "rotation", target_rot, PUFF_ROTATE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _begin_burn_on_ashtray() -> void:
	_set_smoke(true)
	_start_burn()


func _start_burn() -> void:
	_stop_burn()
	_burn_tween = create_tween()
	_burn_tween.tween_method(_apply_length_ratio, 1.0, STUB_WIDTH_RATIO, BURN_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	_burn_tween.tween_callback(_finish_burn)


func _apply_length_ratio(ratio: float) -> void:
	if _texture_size == Vector2.ZERO:
		return
	var width: float = _texture_size.x * ratio
	var region := Rect2(0.0, 0.0, width, _texture_size.y)
	_body.region_rect = region
	_sync_shadow_to_body(region)
	var tip_x: float = width * _body.scale.x
	_smoke.position = Vector2(tip_x, 0.0)
	if ratio <= STUB_WIDTH_RATIO + 0.02:
		_body.modulate = Color(0.72, 0.7, 0.68, 1.0)


func _sync_shadow_to_body(region: Rect2) -> void:
	_cien.region_enabled = true
	_cien.region_rect = region
	_cien.offset = _body.offset
	_cien.position = _body.position + SHADOW_OFFSET


func _finish_burn() -> void:
	_state = State.STUB
	_set_smoke(false)
	burned_out.emit()


func _set_smoke(on: bool) -> void:
	_smoke.emitting = on


func _stop_burn() -> void:
	if _burn_tween and _burn_tween.is_valid():
		_burn_tween.kill()
	_burn_tween = null


func _stop_place_tween() -> void:
	if _place_tween and _place_tween.is_valid():
		_place_tween.kill()
	_place_tween = null


func _stop_puff_tween() -> void:
	if _puff_tween and _puff_tween.is_valid():
		_puff_tween.kill()
	_puff_tween = null
