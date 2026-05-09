extends Node2D

@onready var node_2d: Node2D = $paper_node2d;
@onready var marker: Node2D = $marker_Node2D;

var viewport_size:Vector2;
var mouse_start_pos:Vector2 = Vector2(0,0);
var is_dragging:bool=false;
var line_color:Color = Color(Color.CRIMSON);

const TOILET_SCN = preload("res://toilet_msg.tscn");

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
	if event.is_action_pressed("rand_toilet_msg"):
		new_tolilet_msgs();
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			node_2d.position.y+=50*event.factor;
			node_2d.position.y= min(0,node_2d.position.y);
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN and event.pressed and not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
			node_2d.position.y-=50*event.factor;
			node_2d.position.y = max(node_2d.position.y, -1*(node_2d.get_height() - viewport_size.y));

func _on_ready() -> void:
	viewport_size = get_viewport().get_visible_rect().size;
	pass # Replace with function body.

func _on_draw() -> void:
	pass # Replace with function body.

func _process(_delta):
	marker.position = get_local_mouse_position();
	pass;

func clear_toiler() -> void:
	for child in %toilet_msgs_container.get_children():
		child.queue_free();
	pass
		
func new_tolilet_msgs() -> void:
	var max_msgs:int = 4;
	var y_pad_perct = 0.2;
	var y_padding = viewport_size.y*y_pad_perct;
	var y_spacer = viewport_size.y*(1.0-y_pad_perct) / max_msgs;
	
	var words = WordManager.get_next_batch(max_msgs);
	
	for i in range(max_msgs):
		var toilet_msg = TOILET_SCN.instantiate()
		%toilet_msgs_container.add_child(toilet_msg);
		toilet_msg.position.y = -100;
		toilet_msg.set_label(words[i]);
		toilet_msg.prep_tween();
		var tween = create_tween().set_parallel(true)
		var target_x = randf_range(-50,50);
		var target_y = y_padding + (y_spacer * i);
		target_y+=randf_range(-1*y_padding*0.1, y_padding*0.1);
		tween.tween_property(toilet_msg, "position:y", target_y, 0.6)\
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(toilet_msg, "position:x", target_x, 0.6)\
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	pass
