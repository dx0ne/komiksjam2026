extends Sprite2D

var dragging = false
var rel_pos:Vector2;
var rel_rot:float;
#		
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		rel_pos = (event).position - self.position;
		rel_rot = (self.position - event.position).angle();

		if not dragging and event.pressed and self.get_rect().has_point(get_local_mouse_position()):
			dragging = true
		if dragging and event.is_released():
			dragging = false

	if event is InputEventMouseMotion and dragging:
		# While dragging, move the sprite with the mouse.
		var rel:Vector2 = self.position - event.position;
		self.position = event.position + rel.normalized() * rel_pos.length();
		self.rotation = rel.normalized().angle() - rel_rot;
