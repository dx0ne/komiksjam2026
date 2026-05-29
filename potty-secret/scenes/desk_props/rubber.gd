extends Node2D

signal erase_requested

enum State { LANDING, IDLE, WALKING, FLYING_AWAY, RETURNING }

const CLICK_PADDING := Vector2(16.0, 16.0)
const LAND_DROP_Y := 140.0
const HOP_DURATION := 0.05
const HOP_PAUSE_MIN := 0.03
const HOP_PAUSE_MAX := 0.14
const WALK_RADIUS := 20.0
const WALK_HOPS_MIN := 2
const WALK_HOPS_MAX := 5
const WALK_PAUSE_MIN := 0.2
const WALK_PAUSE_MAX := 1.5
const CLICK_FLEE_POINTS := 6
const CLICK_FLEE_SPREAD := 90.0
const DRAW_FLEE_OFFSET := Vector2(55.0, -45.0)
const SPRITE_FORWARD := Vector2(1.0, 0.0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _home_position := Vector2.ZERO
var _state := State.IDLE
var _motion_tween: Tween
var _walk_timer := 0.0
var _can_interact := false
var _drawing_flee := false
var _click_flee := false


func _ready() -> void:
	_home_position = position
	_set_animation("idle")


func _process(delta: float) -> void:
	if _state != State.IDLE or not _can_interact:
		return
	_walk_timer -= delta
	if _walk_timer <= 0.0:
		_do_walk_step()


func play_entrance() -> void:
	if not visible:
		return
	_kill_motion()
	_drawing_flee = false
	_click_flee = false
	_can_interact = false
	_state = State.LANDING
	_set_animation("fly")
	position = _home_position + Vector2(randf_range(-8.0, 8.0), -LAND_DROP_Y)
	rotation = randf_range(-0.4, 0.4)
	modulate.a = 0.85

	var mid := _home_position + Vector2(randf_range(-10.0, 10.0), -36.0)
	var settle := _home_position + Vector2(randf_range(-4.0, 4.0), 4.0)
	_motion_tween = create_tween()
	_append_hop(_motion_tween, mid, 0.07)
	_append_hop(_motion_tween, settle, 0.05)
	_append_hop(_motion_tween, _home_position, 0.04)
	_motion_tween.tween_property(self, "modulate:a", 1.0, 0.0)
	_motion_tween.tween_callback(_begin_idle)


func reset_fly() -> void:
	_kill_motion()
	_drawing_flee = false
	_click_flee = false
	_can_interact = false
	_state = State.IDLE
	position = _home_position
	rotation = 0.0
	modulate.a = 1.0
	_set_animation("idle")


func notify_marker_drawing(active: bool) -> void:
	if not visible or _click_flee:
		return
	if active:
		if _state in [State.IDLE, State.WALKING]:
			_flee_from_drawing()
	else:
		if _drawing_flee and not _click_flee:
			_return_from_drawing()


func contains_global_point(global_point: Vector2) -> bool:
	if _sprite == null or _sprite.sprite_frames == null:
		return false
	var texture := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if texture == null:
		return false
	var size := texture.get_size()
	var local := _sprite.get_global_transform_with_canvas().affine_inverse() * global_point
	return Rect2(-size * 0.5, size).grow_individual(
		CLICK_PADDING.x,
		CLICK_PADDING.y,
		CLICK_PADDING.x,
		CLICK_PADDING.y
	).has_point(local)


func _input(event: InputEvent) -> void:
	if not visible or not _can_interact:
		return
	if _state != State.IDLE and _state != State.WALKING:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and contains_global_point(event.global_position):
		_on_clicked()
		get_viewport().set_input_as_handled()


func _on_clicked() -> void:
	_click_flee = true
	_drawing_flee = false
	_can_interact = false
	_kill_motion()
	_state = State.FLYING_AWAY
	_set_animation("fly")
	erase_requested.emit()
	_chaotic_fly_and_return()


func _begin_idle() -> void:
	_state = State.IDLE
	_can_interact = true
	_set_animation("idle")
	_schedule_walk()


func _schedule_walk() -> void:
	_walk_timer = randf_range(WALK_PAUSE_MIN, WALK_PAUSE_MAX)


func _do_walk_step() -> void:
	if _state != State.IDLE or not _can_interact:
		return
	_state = State.WALKING
	_set_animation("walk")
	var final_target := _clamp_to_walk_radius(_home_position + _random_walk_offset())
	var hop_count := randi_range(WALK_HOPS_MIN, WALK_HOPS_MAX)
	var hops: Array[Vector2] = []
	for i in range(hop_count):
		var t := float(i + 1) / float(hop_count)
		var wobble := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		hops.append(_clamp_to_walk_radius(position.lerp(final_target, t) + wobble))

	_motion_tween = create_tween()
	for hop in hops:
		_append_hop(_motion_tween, hop)
	_motion_tween.tween_callback(func() -> void:
		_state = State.IDLE
		_set_animation("idle")
		_schedule_walk()
	)


func _flee_from_drawing() -> void:
	_drawing_flee = true
	_kill_motion()
	_state = State.FLYING_AWAY
	_set_animation("fly")
	_can_interact = false
	var jitter := Vector2(randf_range(-24.0, 24.0), randf_range(-16.0, 8.0))
	var away := _home_position + DRAW_FLEE_OFFSET + jitter
	_motion_tween = create_tween()
	_append_hop(_motion_tween, away, 0.04)


func _return_from_drawing() -> void:
	if _click_flee:
		return
	_drawing_flee = false
	_kill_motion()
	_state = State.RETURNING
	_set_animation("fly")
	var target := _clamp_to_walk_radius(_home_position + _random_walk_offset() * 0.35)
	_motion_tween = create_tween()
	_append_hop(_motion_tween, target, 0.05)
	_motion_tween.tween_callback(_begin_idle)


func _chaotic_fly_and_return() -> void:
	var points: Array[Vector2] = []
	for i in range(CLICK_FLEE_POINTS):
		var spread := CLICK_FLEE_SPREAD * (1.0 + float(i) * 0.18)
		points.append(_home_position + Vector2(
			randf_range(-spread, spread),
			randf_range(-spread * 0.75, spread * 0.35)
		))
	points.append(_clamp_to_walk_radius(_home_position + _random_walk_offset() * 0.5))

	_motion_tween = create_tween()
	for flee_target in points:
		_append_hop(_motion_tween, flee_target, randf_range(0.03, 0.06))
	_motion_tween.tween_callback(func() -> void:
		_click_flee = false
		_begin_idle()
	)


func _append_hop(tween: Tween, target: Vector2, hop_duration: float = HOP_DURATION) -> void:
	var direction := target - position
	tween.tween_callback(_aim_at_direction.bind(direction))
	tween.tween_property(self, "position", target, hop_duration) \
		.set_trans(Tween.TRANS_LINEAR)
	tween.tween_interval(randf_range(HOP_PAUSE_MIN, HOP_PAUSE_MAX))


func _aim_at_direction(direction: Vector2) -> void:
	if direction.length_squared() < 1.0:
		return
	rotation = direction.angle() - SPRITE_FORWARD.angle()


func _random_walk_offset() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(5.0, WALK_RADIUS)
	return Vector2(cos(angle), sin(angle)) * dist


func _clamp_to_walk_radius(target: Vector2) -> Vector2:
	var offset := target - _home_position
	if offset.length() > WALK_RADIUS:
		offset = offset.limit_length(WALK_RADIUS)
	return _home_position + offset


func _kill_motion() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null


func _set_animation(animation_name: StringName) -> void:
	if _sprite == null or _sprite.animation == animation_name:
		return
	_sprite.play(animation_name)
