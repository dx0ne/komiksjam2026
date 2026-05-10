extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://intro_scene.tscn");
	pass # Replace with function body.

func _process(_delta):
	%marker_Node2Dd.position = get_local_mouse_position();
	pass;
