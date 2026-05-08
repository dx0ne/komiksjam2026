extends Node2D



func _on_ready() -> void:
	for node in $interactables.get_children():
		if node is TextureButton:
			node.on_redacted_clicked.connect(some_redacted_kliked);
	pass # Replace with function body.

func some_redacted_kliked(idname:String):
	print(idname+" redacted")
	pass;
