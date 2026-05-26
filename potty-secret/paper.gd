class_name GamePaper
extends Node2D

@onready var text_renderer: TextRenderer = %TextRenderer
@onready var marker_layer: MarkerLayer = %MarkerLayer
@onready var debug_overlay: DebugOverlay = %DebugOverlay
@onready var _stamp: Sprite2D = %Stamp


func _ready() -> void:
	set_postit(0, 0)
	set_shift_score(0)
	set_penalty(0)
	set_stamp_visible(false)


func set_postit(marked: int, total: int) -> void:
	if not is_node_ready():
		return
	%pointsLabel.text = "+%d/%d" % [marked, total]


func set_shift_score(score: float) -> void:
	if not is_node_ready():
		return
	if score > 0:
		%pointsLabel_good.text = "+%.1f" % score
	elif score < 0:
		%pointsLabel_good.text = "%.1f" % score
	else:
		%pointsLabel_good.text = ""


func set_penalty(amount: int) -> void:
	if not is_node_ready():
		return
	if amount > 0:
		%pointsLabel_bad.text = "-%d" % amount
	else:
		%pointsLabel_bad.text = ""


func set_stamp_visible(show_stamp: bool) -> void:
	if not is_instance_valid(_stamp):
		return
	_stamp.visible = show_stamp
	if not show_stamp:
		_stamp.modulate = Color.WHITE
		_stamp.scale = Vector2(0.55, 0.55)
		return
	_stamp.modulate.a = 0.0
	_stamp.scale = Vector2(0.66, 0.66)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_stamp, "modulate:a", 1.0, 0.08)
	tween.tween_property(_stamp, "scale", Vector2(0.55, 0.55), 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func marker_point_to_text_local(point: Vector2) -> Vector2:
	return point + marker_layer.position - text_renderer.position
