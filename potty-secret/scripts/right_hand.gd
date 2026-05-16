extends Node2D

## Player tool hand — follows the mouse like a cursor. Swap tools via `set_tool()` later.

@export var follow_mouse := true
@export var hide_system_cursor := true
@export var cursor_offset := Vector2.ZERO

var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	if hide_system_cursor:
		_previous_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _exit_tree() -> void:
	if hide_system_cursor:
		Input.set_mouse_mode(_previous_mouse_mode)


func _process(_delta: float) -> void:
	if follow_mouse:
		global_position = get_viewport().get_mouse_position() + cursor_offset


func set_tool(_tool_id: StringName) -> void:
	# Stub for future tools (marker, stamp, etc.).
	pass
