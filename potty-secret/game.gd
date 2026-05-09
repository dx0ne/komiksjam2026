extends Node2D

@onready var node_2d: Node2D = $paper_node2d;
@onready var marker: Node2D = $marker_Node2D;

var viewport_size:Vector2;
var mouse_start_pos:Vector2 = Vector2(0,0);
var is_dragging:bool=false;
var line_color:Color = Color(Color.CRIMSON);

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit();
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
