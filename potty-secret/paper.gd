class_name Paper
extends Node2D

@onready var texture:Sprite2D = $Sprite2D;

#how many good redactions
var count_correct_redacted:int;
#hom many TOTAL redactions
var count_all_redacted:int;

func _on_ready() -> void:
	for node in %interactables.get_children():
		if node is RedactedLabel:
			node.on_redacted_clicked.connect(some_redacted_kliked);
			node.on_started_good.connect(_on_started_good);
			node.on_zjebane.connect(_on_zjebane);
	%Sprite2D.rotation = deg_to_rad(randf_range(-2.0,2.0));
	#%Sprite2D.position = Vector2(randf_range(-30.0,0), randf_range(-30.0,0));
	update_points();
	pass # Replace with function body.

func some_redacted_kliked(idname:String):
	count_all_redacted+=1;
	if(WordManager.current_toilet_words.has(idname)):
		print(idname+" redacted");
		(%lines as LinePainter)._on_ended_good();
		count_correct_redacted+=1;
	else:
		(%lines as LinePainter)._on_not_banned();
	update_points()
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

func update_points() -> void:
	var current = count_correct_redacted # Replace with your actual score variable
	var total = %interactables.get_child_count()
	%pointsLabel.text = str(count_all_redacted) + " / " + str(total);
	if count_correct_redacted>0:
		%pointsLabel_good.text = "+"+str(count_correct_redacted);
	else:
		%pointsLabel_good.text = "";
	if count_correct_redacted - count_all_redacted < 0:
		%pointsLabel_bad.text = str(count_correct_redacted - count_all_redacted)
	else:
		%pointsLabel_bad.text = "";
	pass;
