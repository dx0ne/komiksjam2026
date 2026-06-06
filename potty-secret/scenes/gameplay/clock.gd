class_name ShiftClock
extends Node2D

@onready var game_timer: Timer = %Timer
@onready var progress_bar = $ProgressBar
@onready var reka_zegarek: Sprite2D = %RekaZegarek
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var _reka_start_rotation: float

var time_left: float:
	get: return game_timer.time_left if game_timer else 0.0

signal time_out();

func _on_timer_timeout() -> void:
	time_out.emit();
	pass # Replace with function body.


func _on_ready() -> void:
	game_timer.wait_time = 180.0
	progress_bar.max_value = game_timer.wait_time
	progress_bar.value = game_timer.wait_time
	_reka_start_rotation = reka_zegarek.rotation


func start_shift() -> void:
	game_timer.wait_time = 180.0
	game_timer.start()
	progress_bar.max_value = game_timer.wait_time
	progress_bar.value = game_timer.time_left


func add_time(seconds: float) -> void:
	if game_timer.is_stopped():
		return
	game_timer.start(game_timer.time_left + seconds)
	progress_bar.max_value = game_timer.wait_time
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
	progress_bar.max_value = game_timer.wait_time
	progress_bar.value = game_timer.time_left


func _process(_delta):
	if not game_timer.is_stopped():
		progress_bar.value = game_timer.time_left
		var progress: float = 1.0 - (game_timer.time_left / game_timer.wait_time)
		reka_zegarek.rotation = _reka_start_rotation + progress * TAU
		animation_player.speed_scale = 2.0 if progress >= 0.75 else 1.0
