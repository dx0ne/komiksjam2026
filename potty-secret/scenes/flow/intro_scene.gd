extends Control

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
	if event.is_action_pressed("next_document"):
		_on_video_stream_player_finished();

func _on_video_stream_player_finished():
	# Replace with the path to your actual main menu scene
	get_tree().change_scene_to_file("res://scenes/flow/main_menu.tscn")
