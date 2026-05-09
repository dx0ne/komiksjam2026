extends Node2D


@onready var marker: Node2D = $marker_Node2D;

var viewport_size:Vector2;
var mouse_start_pos:Vector2 = Vector2(0,0);
var is_dragging:bool=false;
var line_color:Color = Color(Color.CRIMSON);

const TOILET_SCN = preload("res://toilet_msg.tscn");
const PAPER_SCN = preload("res://paper.tscn");

var papers:Array[Paper];
var current_paper_idx:int=-1;
var paper_node: Node2D;;

var current_words:Array[String];

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
	if event.is_action_pressed("rand_toilet_msg"):
		new_tolilet_msgs();
	if event.is_action_pressed("rand_document"):
		add_document();
	if event.is_action_pressed("next_document"):
		next_document();
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			paper_node.position.y+=50*event.factor;
			paper_node.position.y= min(0,paper_node.position.y);
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN and event.pressed and not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
			paper_node.position.y-=50*event.factor;
			paper_node.position.y = max(paper_node.position.y, -1*(paper_node.get_height() - viewport_size.y));

func _on_ready() -> void:
	viewport_size = get_viewport().get_visible_rect().size;
	for i in range(3):
		add_document();    
		await get_tree().create_timer(0.3).timeout
	new_tolilet_msgs();
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
	WordManager.current_toilet_words=words;
	
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

func add_document() -> void:
	var paper = PAPER_SCN.instantiate()
	%papers_container.add_child(paper);
	paper_node = paper;
	papers.append(paper);
	current_paper_idx = papers.size()-1;
	var tween = create_tween();
	paper_node.position += Vector2(200,100);
	var offset_pos = Vector2(randf_range(-30.0,0), randf_range(-30.0,0));
	tween.tween_property(paper_node, "position", offset_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	pass

func next_document() -> void:
	papers[current_paper_idx].process_mode = Node.PROCESS_MODE_DISABLED;
	current_paper_idx+=1;
	if(current_paper_idx >= papers.size()):
		current_paper_idx=0;
	#%papers_container.move_child(papers[current_paper_idx], -1);
	paper_node = papers[current_paper_idx]
	paper_node.process_mode = Node.PROCESS_MODE_INHERIT;
	var tween = create_tween();
	var original_pos = Vector2(randf_range(-30.0,0), randf_range(-30.0,0));#papers[current_paper_idx].position;
	var offset_pos = original_pos + Vector2(200,100);
	
	var trans_time:float = 0.2;
	
	tween.set_parallel(true)
	tween.tween_property(paper_node, "position", offset_pos, trans_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(paper_node, "scale", Vector2(1.1, 1.1), 0.3)
	
	tween.set_parallel(false)
	tween.tween_callback(%papers_container.move_child.bind(paper_node, -1));
	
	tween.set_parallel(true)
	tween.tween_property(paper_node, "position", original_pos, trans_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	#tween.tween_property(paper_node, "scale", Vector2(1, 1), trans_time)
	pass

func _on_gimme_toilet_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toilet_pull();
	pass # Replace with function body.

func toilet_pull() -> void:
			
	var tween = create_tween();
	var original_pos = Vector2(0,0);
	var offset_pos = original_pos + Vector2(0,100);
	
	var trans_time:float = 0.2;
	
	#tween.set_parallel(true)
	tween.tween_property(%gimme_toilet_btn, "position", offset_pos, trans_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(paper_node, "scale", Vector2(1.1, 1.1), 0.3)
	
	#tween.set_parallel(false)
	
	tween.tween_property(%gimme_toilet_btn, "position", original_pos, trans_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(new_tolilet_msgs);
	pass
