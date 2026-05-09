class_name Paper
extends Node2D

@onready var texture:Sprite2D = $Sprite2D;

func _on_ready() -> void:
	for node in %interactables.get_children():
		if node is RedactedLabel:
			node.on_redacted_clicked.connect(some_redacted_kliked);
			node.on_started_good.connect(_on_started_good);
			node.on_zjebane.connect(_on_zjebane);
	pass # Replace with function body.

func some_redacted_kliked(idname:String):
	print(idname+" redacted");
	(%lines as LinePainter)._on_ended_good();
	pass;

func get_height() -> float:
	return texture.get_rect().size.y * texture.scale.y;

func has_point() -> bool:
	var global_mouse_pos = get_global_mouse_position()
	var local_point = texture.to_local(global_mouse_pos)
	return texture.get_rect().has_point(local_point);

func _on_started_good() -> void:
	(%lines as LinePainter)._on_started_good();
	pass;
	
func _on_zjebane() -> void:
	(%lines as LinePainter)._on_zjebane();
	pass;
