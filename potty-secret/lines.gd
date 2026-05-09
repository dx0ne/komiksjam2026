extends Node2D

var is_drawing_enabled:bool=true;

var parent:Paper;

var lines:PackedVector2Array;

var mouse_start_pos:Vector2 = Vector2(0,0);
var is_dragging:bool=false;
var line_color:Color = Color(Color.BLACK,0.5);
var last_mouse_safe_pos:Vector2;

func _on_draw() -> void:
	if(lines.size() > 1):
		draw_multiline(lines,line_color,30,false);
	pass # Replace with function body.

func _input(event):
	if not is_drawing_enabled:
		return;
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and parent.has_point():
			last_mouse_safe_pos = get_local_mouse_position();
			is_dragging=true;
			lines.append(last_mouse_safe_pos);
			lines.append(last_mouse_safe_pos);
		else:
			is_dragging=false;
			queue_redraw();
	if event is InputEventMouseMotion and is_dragging:
		if(parent.has_point()):
			last_mouse_safe_pos = get_local_mouse_position();
			lines[-1] = last_mouse_safe_pos;
		else:
			is_dragging=false;
		queue_redraw();


func _on_ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN;
	parent = get_parent() as Paper;
	if parent == null:
		parent = get_parent().get_parent() as Paper;
	pass # Replace with function body.
