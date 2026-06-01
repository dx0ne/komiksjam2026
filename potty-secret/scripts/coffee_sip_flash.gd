extends ColorRect

@export_group("Flash timing")
@export var peak_brightness := 0.36
@export var flash_duration := 1.0

@export_group("Flash blend (shader)")
@export_range(0.0, 1.0, 0.01) var lighten_mix := 1.0
@export_range(0.0, 1.0, 0.01) var screen_mix := 0.55
@export_range(0.0, 1.0, 0.01) var luma_lift := 0.55
@export_range(0.0, 0.3, 0.01) var luma_boost := 0.05
@export_range(0.0, 1.5, 0.01) var sat_boost := 0.4
@export_range(0.0, 0.5, 0.01) var screen_push := 0.12

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_shader_tuning()
	_set_brightness(0.0)


func _apply_shader_tuning() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("lighten_mix", lighten_mix)
	mat.set_shader_parameter("screen_mix", screen_mix)
	mat.set_shader_parameter("luma_lift", luma_lift)
	mat.set_shader_parameter("luma_boost", luma_boost)
	mat.set_shader_parameter("sat_boost", sat_boost)
	mat.set_shader_parameter("screen_push", screen_push)


func play_flash() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_set_brightness(0.0)
	var rise := flash_duration * 0.22
	var fall := flash_duration - rise
	_tween = create_tween()
	_tween.tween_method(_set_brightness, 0.0, peak_brightness, rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_brightness, peak_brightness, 0.0, fall) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _set_brightness(value: float) -> void:
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("brighten", value)
