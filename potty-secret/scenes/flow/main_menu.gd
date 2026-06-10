extends Control

const RedactionCoverageScript := preload("res://scripts/redaction_coverage.gd")
const REDACTION_TOLERANCE := 12.0

@export var debug_redaction := false
@export var accept_half_coverage := true

@onready var marker_layer: MarkerLayer = %MarkerLayer
@onready var play_label: Label = %PlayLabel
@onready var save_label: Label = %SaveLabel
@onready var redaction_debug: Control = %RedactionDebug

var _play_rect_global := Rect2()
var _save_rect_global := Rect2()
var _game_started := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	%PlayButton.visible = false
	marker_layer.hide_os_cursor = false
	marker_layer.stroke_finished.connect(_on_marker_stroke_finished)
	get_viewport().size_changed.connect(_fit_marker_layer)
	resized.connect(_update_label_rects)
	play_label.resized.connect(_update_label_rects)
	save_label.resized.connect(_update_label_rects)
	save_label.visible = PlayerProgress.has_completed_onboarding()
	_fit_marker_layer()
	call_deferred("_update_label_rects")
	AudioManager.play_menu_ambient()


func _fit_marker_layer() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	marker_layer.position = Vector2.ZERO
	marker_layer.size = vp_size
	if redaction_debug != null:
		redaction_debug.position = Vector2.ZERO
		redaction_debug.size = vp_size
	_update_label_rects()


func _update_label_rects() -> void:
	_play_rect_global = play_label.get_global_rect()
	_save_rect_global = save_label.get_global_rect()
	if redaction_debug != null:
		var inv := redaction_debug.get_global_transform_with_canvas().affine_inverse()
		redaction_debug.target_rect = inv * _play_rect_global
		redaction_debug.tolerance = REDACTION_TOLERANCE
		redaction_debug.queue_redraw()
	if debug_redaction:
		print(
			"[main_menu] play global rect=%s  save global rect=%s  marker_size=%s"
			% [_play_rect_global, _save_rect_global, marker_layer.size]
		)


func _on_marker_stroke_finished(_stroke: PackedVector2Array) -> void:
	if _game_started:
		return

	var tier := _coverage_tier_for_play()
	var cells := _coverage_cells_for_play()
	var status := "tier=%s cells=%s strokes=%d" % [tier, cells, marker_layer.strokes.size()]

	if redaction_debug != null:
		redaction_debug.status_text = status
		redaction_debug.queue_redraw()
	if debug_redaction:
		print("[main_menu] stroke finished — %s" % status)

	if save_label.visible and _tier_passes(_coverage_tier_for_rect(_save_rect_global)):
		PlayerProgress.reset_onboarding()
		save_label.visible = false
		marker_layer.clear_strokes()
		AudioManager.play_sfx("menu_save_wipe")
		if debug_redaction:
			print("[main_menu] GAME SAVED redacted — progress wiped")
		return

	if not _tier_passes(tier):
		return

	_game_started = true
	marker_layer.set_locked(true)
	AudioManager.play_sfx("menu_play_confirmed")
	if debug_redaction:
		print("[main_menu] PLAY redacted — starting game")
	_start_game()


func _tier_passes(tier: String) -> bool:
	if tier == "full":
		return true
	return accept_half_coverage and tier == "half"


func _global_strokes() -> Array:
	var global_strokes: Array = []
	var to_global := marker_layer.get_global_transform_with_canvas()
	for stroke in marker_layer.strokes:
		var global_stroke := PackedVector2Array()
		for point in stroke:
			global_stroke.append(to_global * point)
		global_strokes.append(global_stroke)
	return global_strokes


func _coverage_tier_for_play() -> String:
	return _coverage_tier_for_rect(_play_rect_global)


func _coverage_tier_for_rect(rect: Rect2) -> String:
	if rect.size == Vector2.ZERO:
		return "none"
	return RedactionCoverageScript.coverage_tier(
		_global_strokes(),
		rect,
		REDACTION_TOLERANCE
	)


func _coverage_cells_for_play() -> String:
	var grown := _play_rect_global.grow(REDACTION_TOLERANCE)
	var cell_total := maxi(1, ceili(grown.size.x / RedactionCoverageScript.COVERAGE_CELL_WIDTH))
	var touched := {}
	for stroke in _global_strokes():
		for point in RedactionCoverageScript.sample_stroke(stroke):
			if not grown.has_point(point):
				continue
			var ci := clampi(
				floori((point.x - grown.position.x) / RedactionCoverageScript.COVERAGE_CELL_WIDTH),
				0,
				cell_total - 1
			)
			touched[ci] = true
	return "%d/%d" % [touched.size(), cell_total]


func _start_game() -> void:
	AudioManager.stop_menu_ambient()
	get_tree().change_scene_to_file("res://scenes/flow/game2.tscn")


func _on_play_button_pressed() -> void:
	_start_game()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/flow/intro_scene.tscn")
