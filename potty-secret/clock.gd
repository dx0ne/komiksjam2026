extends Node2D

@onready var game_timer = $Timer
@onready var progress_bar = $ProgressBar

signal time_out();

func _on_timer_timeout() -> void:
	time_out.emit();
	pass # Replace with function body.


func _on_ready() -> void:
	game_timer.wait_time=180;
	progress_bar.max_value = game_timer.wait_time
	progress_bar.value = game_timer.wait_time
	game_timer.start();
	pass # Replace with function body.

func _process(_delta):
	if not game_timer.is_stopped():
		progress_bar.value = game_timer.time_left
