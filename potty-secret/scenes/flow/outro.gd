extends Control

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
	if event.is_action_pressed("next_document"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
