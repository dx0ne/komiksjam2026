extends Node2D

@onready var node_2d: Node2D = $Node2D

var viewport_size:Vector2;

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Left button was clicked at ", event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			print("Wheel up "+str(event.factor))
			node_2d.position.y+=50*event.factor;
			node_2d.position.y= min(0,node_2d.position.y);
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			print("Wheel down "+str(event.factor))
			node_2d.position.y-=50*event.factor;
			node_2d.position.y = max(node_2d.position.y, -1*(node_2d.get_height() - viewport_size.y));


func _on_ready() -> void:
	viewport_size = get_viewport().get_visible_rect().size;
	pass # Replace with function body.
