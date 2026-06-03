class_name GamePaper
extends Node2D

@onready var text_renderer: TextRenderer = %TextRenderer
@onready var marker_layer: MarkerLayer = %MarkerLayer
@onready var debug_overlay: DebugOverlay = %DebugOverlay
@onready var _stamp: Sprite2D = %Stamp

var _stamp_tween: Tween = null


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


func _kill_stamp_tween() -> void:
	if _stamp_tween != null and _stamp_tween.is_valid():
		_stamp_tween.kill()
	_stamp_tween = null


func stabilize_stamp_for_exit() -> void:
	if not is_instance_valid(_stamp) or not _stamp.visible:
		return
	_kill_stamp_tween()
	_stamp.modulate = Color.WHITE
	_stamp.scale = Vector2(0.55, 0.55)


func set_stamp_visible(show_stamp: bool) -> void:
	if not is_instance_valid(_stamp):
		return
	_kill_stamp_tween()
	_stamp.visible = show_stamp
	if not show_stamp:
		_stamp.modulate = Color.WHITE
		_stamp.scale = Vector2(0.55, 0.55)
		return
	_stamp.modulate = Color.WHITE
	_stamp.scale = Vector2(0.66, 0.66)
	_stamp_tween = create_tween()
	_stamp_tween.set_parallel(true)
	_stamp_tween.tween_property(_stamp, "scale", Vector2(0.55, 0.55), 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_stamp_tween.finished.connect(func() -> void: _stamp_tween = null)


func set_onboarding_ui(active: bool, sticky_hint: String = "") -> void:
	if not is_node_ready():
		await ready
	var posit := get_node_or_null("Posit")
	if posit == null:
		return
	%pointsLabel.visible = not active
	%pointsLabel_good.visible = not active
	%pointsLabel_bad.visible = not active
	if active and not sticky_hint.is_empty():
		%pointsLabel.visible = true
		%pointsLabel.text = sticky_hint
		%pointsLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		%pointsLabel.offset_left = -95.0
		%pointsLabel.offset_top = -110.21475
		%pointsLabel.offset_right = 5.0
		%pointsLabel.offset_bottom = 6.785248
	elif active:
		%pointsLabel.visible = false
	else:
		%pointsLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%pointsLabel.offset_left = -68.2852
		%pointsLabel.offset_top = -110.21475
		%pointsLabel.offset_right = 37.714798
		%pointsLabel.offset_bottom = 6.785248


func marker_point_to_text_local(point: Vector2) -> Vector2:
	return point + marker_layer.position - text_renderer.position
