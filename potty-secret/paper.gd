class_name GamePaper
extends Node2D

## When false, TextRenderer skips the ministry letterhead (e.g. topic newspapers).
@export var show_letterhead := true

@onready var text_renderer: TextRenderer = %TextRenderer
@onready var marker_layer: MarkerLayer = %MarkerLayer
@onready var debug_overlay: DebugOverlay = %DebugOverlay
@onready var _stamp: Sprite2D = %Stamp

var _stamp_tween: Tween = null


func _ready() -> void:
	text_renderer.show_letterhead = show_letterhead
	set_postit(0, 0)
	set_shift_score(0)
	set_penalty(0)
	set_stamp_visible(false)
	if has_node("%PostItHint"):
		%PostItHint.visible = false
		%PostItHint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var posit := get_node_or_null("Posit")
	if posit != null:
		posit.z_index = 10
	if is_instance_valid(marker_layer):
		marker_layer.z_index = 20
		_align_marker_layer_to_text()


func _align_marker_layer_to_text() -> void:
	marker_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	marker_layer.position = text_renderer.position
	marker_layer.size = text_renderer.size


func set_postit(marked: int, total: int) -> void:
	if not is_node_ready():
		return
	%pointsLabel.text = "+%d/%d" % [marked, total]


func set_shift_score(_score: float) -> void:
	if not is_node_ready():
		return
	%pointsLabel_good.visible = false
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
	%pointsLabel_good.visible = false
	%pointsLabel_bad.visible = not active

	var post_it_hint: Label = get_node_or_null("%PostItHint") as Label
	if post_it_hint != null:
		%pointsLabel.visible = not active
		post_it_hint.visible = active and not sticky_hint.is_empty()
		if active and not sticky_hint.is_empty():
			post_it_hint.text = sticky_hint
		return

	%pointsLabel.visible = not active
	if active and not sticky_hint.is_empty():
		%pointsLabel.visible = true
		%pointsLabel.text = sticky_hint
		%pointsLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		%pointsLabel.offset_left = -72.0
		%pointsLabel.offset_top = -62.29529
		%pointsLabel.offset_right = 72.0
		%pointsLabel.offset_bottom = 54.70471
	elif active:
		%pointsLabel.visible = false
	else:
		%pointsLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%pointsLabel.offset_left = -68.2852
		%pointsLabel.offset_top = -110.21475
		%pointsLabel.offset_right = 37.714798
		%pointsLabel.offset_bottom = 6.785248


func marker_point_to_text_local(point: Vector2) -> Vector2:
	var marker_xform := marker_layer.get_global_transform_with_canvas()
	var text_xform := text_renderer.get_global_transform_with_canvas()
	return text_xform.affine_inverse() * marker_xform * point
