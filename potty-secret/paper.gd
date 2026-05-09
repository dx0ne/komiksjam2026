class_name Paper
extends Node2D

@onready var texture:Sprite2D = $Sprite2D;

func _on_ready() -> void:
	for node in %interactables.get_children():
		if node is TextureButton:
			node.on_redacted_clicked.connect(some_redacted_kliked);
	pass # Replace with function body.

func some_redacted_kliked(idname:String):
	print(idname+" redacted")
	pass;

func get_height() -> float:
	return texture.get_rect().size.y * texture.scale.y;

func has_point() -> bool:
	var global_mouse_pos = get_global_mouse_position()
	var local_point = texture.to_local(global_mouse_pos)
	return texture.get_rect().has_point(local_point);
