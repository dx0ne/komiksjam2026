class_name LinePainter
extends Node2D

var is_drawing_enabled:bool=true;

var parent:Paper;

var lines:PackedVector2Array;
var colors:PackedColorArray;

var mouse_start_pos:Vector2 = Vector2(0,0);
var is_dragging:bool=false;
var line_color:Color = Color(Color.BLACK,0.5);
var bad_line_color:Color = Color(Color.BLACK,0.5);
var last_mouse_safe_pos:Vector2;

func _on_draw() -> void:
	if(lines.size() > 1):
		draw_multiline_colors(lines,colors,30,false);
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
			colors.append(bad_line_color);
		else:
			is_dragging=false;
			colors[-1] = Color(Color.CRIMSON, 0.9);
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

func _on_started_good() -> void:
	if(colors.size()==0):
		return;
	colors[-1] = Color(line_color);
	pass;

func _on_ended_good() -> void:	
	if(colors.size()==0):
		return;
	colors[-1] = Color(Color.BLACK, 1.0);
	pass
	
func _on_zjebane()-> void:
	if(colors.size()==0):
		return;
	colors[-1] = Color(Color.CRIMSON, 0.99);
	pass

func _on_not_banned()-> void:
	if(colors.size()==0):
		return;
	colors[-1] = Color(Color.CRIMSON, 1.0);
	pass

var fade_speed: float = 0.7

func _process(delta):
	var changed = false
	for i in range(colors.size()):
		if colors[i].a < 1.0 and colors[i].a > 0:
			if (i == colors.size()-1 and is_dragging):
				continue;
			else:
				colors[i].a -= fade_speed * delta;
				changed = true;
			
	if changed:
		queue_redraw() # Tells Godot to call _draw() next frame
