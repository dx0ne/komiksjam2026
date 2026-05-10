class_name ToiletMsg
extends Node2D

func set_label(new_label:String) -> void:
	%Label.text=new_label;
	pass


func _on_rot_node_ready() -> void:
	%rot_node.rotation = deg_to_rad(randf_range(-30, 30));
	%label_rot.rotation = deg_to_rad(randf_range(-30, 30));
	pass
	
func prep_tween() -> void:
	var tween = create_tween().set_parallel(true)
	var random_rotation = randf_range(-0.1*TAU, 0.1*TAU)
	tween.tween_property(%rot_node, "rotation", random_rotation, 0.6)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pass # Replace with function body.
