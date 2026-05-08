extends Node2D

@onready var node_2d: Node2D = $Node2D

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Left button was clicked at ", event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			print("Wheel up "+str(event.factor))
			node_2d.position.y+=50*event.factor;
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			print("Wheel down "+str(event.factor))
			node_2d.position.y-=50*event.factor;
