extends Control


func _on_ready() -> void:
	$VideoStreamPlayer_bad.hide()
	$VideoStreamPlayer_good.hide();
	pass # Replace with function body.
	
func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
	if event.is_action_pressed("next_document"):
		_on_video_stream_player_finished();

func _on_video_stream_player_finished():
	# Replace with the path to your actual main menu scene
	get_tree().change_scene_to_file("res://scenes/flow/outro.tscn")


func _on_video_stream_player_good_finished() -> void:
	_on_video_stream_player_finished();
	pass # Replace with function body.


func _on_video_stream_player_bad_finished() -> void:
	_on_video_stream_player_finished();
	pass # Replace with function body.


func _on_video_stream_player_intro_finished() -> void:
	$VideoStreamPlayer_intro.hide();
	if(WordManager.good_ending):
		$VideoStreamPlayer_good.play();
		$VideoStreamPlayer_good.show();
	else:
		$VideoStreamPlayer_bad.play()
		$VideoStreamPlayer_bad.show()
	pass # Replace with function body.
