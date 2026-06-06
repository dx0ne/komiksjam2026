class_name ShiftClock
extends Node2D

@onready var game_timer: Timer = %Timer
@onready var progress_bar = $ProgressBar
@onready var reka_zegarek: Sprite2D = %RekaZegarek
@onready var animation_player: AnimationPlayer = %LegsAnimationPlayer

var _reka_start_rotation: float

const SHIFT_DURATION_S := 180.0
const DECOR_SPEEDUP_TIME_LEFT_S := 45.0  ## Last 25% of a 180 s shift.
const DECOR_SPEEDUP_SCALE := 2.0

var _palec_animation: AnimationPlayer

var time_left: float:
	get: return game_timer.time_left if game_timer else 0.0

signal time_out();

func _on_timer_timeout() -> void:
	time_out.emit();
	pass # Replace with function body.


func _on_ready() -> void:
	game_timer.wait_time = SHIFT_DURATION_S
	progress_bar.max_value = SHIFT_DURATION_S
	progress_bar.value = SHIFT_DURATION_S
	_reka_start_rotation = reka_zegarek.rotation
	_palec_animation = get_parent().get_node_or_null("Palec2") as AnimationPlayer
	_stop_legs_animation()


func start_shift() -> void:
	game_timer.wait_time = SHIFT_DURATION_S
	game_timer.start()
	progress_bar.max_value = SHIFT_DURATION_S
	progress_bar.value = game_timer.time_left
	reka_zegarek.rotation = _reka_start_rotation
	_start_legs_animation()


func stop_shift() -> void:
	game_timer.stop()
	progress_bar.value = SHIFT_DURATION_S
	reka_zegarek.rotation = _reka_start_rotation
	_stop_legs_animation()


func add_time(seconds: float) -> void:
	if game_timer.is_stopped():
		return
	game_timer.start(game_timer.time_left + seconds)
	progress_bar.max_value = SHIFT_DURATION_S
	progress_bar.value = game_timer.time_left


func set_time_left(seconds: float) -> void:
	if game_timer.is_stopped():
		return
	var new_left := clampf(seconds, 0.0, game_timer.wait_time)
	if new_left <= 0.0:
		game_timer.stop()
		progress_bar.value = 0.0
		time_out.emit()
		return
	game_timer.start(new_left)
	progress_bar.max_value = SHIFT_DURATION_S
	progress_bar.value = game_timer.time_left


func get_shift_elapsed_s() -> float:
	if game_timer.is_stopped():
		return 0.0
	return maxf(0.0, SHIFT_DURATION_S - game_timer.time_left)


func get_shift_progress() -> float:
	return clampf(get_shift_elapsed_s() / SHIFT_DURATION_S, 0.0, 1.0)


func get_decor_speed_scale() -> float:
	if game_timer.is_stopped():
		return 1.0
	return DECOR_SPEEDUP_SCALE if time_left <= DECOR_SPEEDUP_TIME_LEFT_S else 1.0


func _sync_decor_animation_speed() -> void:
	var speed := get_decor_speed_scale()
	animation_player.speed_scale = speed
	if _palec_animation:
		_palec_animation.speed_scale = speed


func _start_legs_animation() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play("nogi")


func _stop_legs_animation() -> void:
	animation_player.stop()
	animation_player.play("RESET")


func _process(_delta):
	if not game_timer.is_stopped():
		progress_bar.value = game_timer.time_left
		var progress := get_shift_progress()
		reka_zegarek.rotation = _reka_start_rotation + progress * TAU
		_sync_decor_animation_speed()
