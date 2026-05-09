extends Node

var dragging = false
var click_radius = 32 # Size of the sprite.
var rel_pos:Vector2;
var rel_rot:float;

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		rel_pos = (event).position - self.position;
		rel_rot = (self.position - event.position).angle();
		if rel_pos.length() < click_radius:
			# Start dragging if the click is on the sprite.
			if not dragging and event.pressed:
				dragging = true
		# Stop dragging if the button is released.
		if dragging and not event.pressed:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		# While dragging, move the sprite with the mouse.
		var rel:Vector2 = self.position - event.position;
		self.position = event.position + rel.normalized() * rel_pos.length();
		self.rotation = rel.normalized().angle() - rel_rot;
