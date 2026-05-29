class_name ToiletMsg
extends Node2D

var _pending_label := ""
var _active_sprite: Sprite2D


func set_label(new_label: String) -> void:
	_pending_label = new_label
	if _active_sprite != null:
		_apply_label_fit()


func _on_rot_node_ready() -> void:
	%rot_node.rotation = deg_to_rad(randf_range(-30, 30))


func prep_tween() -> void:
	var tween := create_tween().set_parallel(true)
	var random_rotation := randf_range(-0.1 * TAU, 0.1 * TAU)
	tween.tween_property(%rot_node, "rotation", random_rotation, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_ready() -> void:
	if Engine.is_editor_hint():
		return

	var sprites_only: Array[Sprite2D] = []
	for child in %rot_node.get_children():
		if child is Sprite2D:
			sprites_only.append(child)
			child.hide()

	if sprites_only.is_empty():
		return

	_active_sprite = sprites_only.pick_random()
	_active_sprite.show()
	_apply_label_fit()


func _sprite_label(sprite: Sprite2D) -> ToiletIntelLabel:
	return sprite.get_node("Label") as ToiletIntelLabel


func _apply_label_fit() -> void:
	if _pending_label.is_empty() or _active_sprite == null:
		return
	_sprite_label(_active_sprite).set_intel_text(_pending_label)
