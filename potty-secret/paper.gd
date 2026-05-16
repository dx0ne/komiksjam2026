class_name Paper
extends Node2D

const STAMPEL_TEXTURE := preload("res://art/stempel.png")

@onready var texture: Sprite2D = $Sprite2D

var count_correct_redacted: int
var count_all_redacted: int
var _stamp: Sprite2D


func _on_ready() -> void:
	for node in %interactables.get_children():
		if node is RedactedLabel:
			node.on_redacted_clicked.connect(some_redacted_kliked)
			node.on_started_good.connect(_on_started_good)
			node.on_zjebane.connect(_on_zjebane)
	%Sprite2D.rotation = deg_to_rad(randf_range(-2.0, 2.0))
	update_points()


func some_redacted_kliked(idname: String) -> void:
	count_all_redacted += 1
	if WordManager.current_toilet_words.has(idname):
		(%lines as LinePainter)._on_ended_good()
		count_correct_redacted += 1
	else:
		(%lines as LinePainter)._on_not_banned()
	update_points()


func get_height() -> float:
	return texture.get_rect().size.y * texture.scale.y


func has_point() -> bool:
	var global_mouse_pos := get_global_mouse_position()
	var local_point := texture.to_local(global_mouse_pos)
	return texture.get_rect().has_point(local_point)


func _on_started_good() -> void:
	(%lines as LinePainter)._on_started_good()


func _on_zjebane() -> void:
	(%lines as LinePainter)._on_zjebane()


func update_points() -> void:
	var total := %interactables.get_child_count()
	%pointsLabel.text = str(count_all_redacted) + " / " + str(total)
	if count_correct_redacted > 0:
		%pointsLabel_good.text = "+" + str(count_correct_redacted)
	else:
		%pointsLabel_good.text = ""
	if count_correct_redacted - count_all_redacted < 0:
		%pointsLabel_bad.text = str(count_correct_redacted - count_all_redacted)
	else:
		%pointsLabel_bad.text = ""


func get_score() -> bool:
	var total := %interactables.get_child_count()
	return count_all_redacted == total and count_correct_redacted == count_all_redacted


func all_filled() -> bool:
	var total := %interactables.get_child_count()
	return count_all_redacted == total


func set_postit(marked: int, total: int) -> void:
	if not is_node_ready():
		return
	%pointsLabel.text = "tak masz %d/%d" % [marked, total]


func set_shift_score(total_correct: int) -> void:
	if total_correct > 0:
		%pointsLabel_good.text = "+%d" % total_correct
	else:
		%pointsLabel_good.text = ""


func set_penalty(amount: int) -> void:
	if amount > 0:
		%pointsLabel_bad.text = "-%d" % amount
	else:
		%pointsLabel_bad.text = ""


func set_stamp_visible(show_stamp: bool) -> void:
	if _stamp:
		_stamp.visible = show_stamp


func prepare_for_game2_overlay() -> void:
	var label: Label = $Sprite2D/Label
	if label:
		label.visible = false
	if %interactables:
		%interactables.visible = false
		%interactables.process_mode = Node.PROCESS_MODE_DISABLED

	if _stamp == null:
		_stamp = Sprite2D.new()
		_stamp.texture = STAMPEL_TEXTURE
		_stamp.position = Vector2(520, 720)
		_stamp.scale = Vector2(0.42, 0.42)
		_stamp.visible = false
		%Sprite2D.add_child(_stamp)

	set_postit(0, 0)
	set_shift_score(0)
	set_penalty(0)
	set_stamp_visible(false)
