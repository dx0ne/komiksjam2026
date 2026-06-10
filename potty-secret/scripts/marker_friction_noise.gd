class_name MarkerFrictionNoise
extends AudioStreamPlayer

## Procedural marker-on-paper friction: band-limited white noise scaled by cursor speed.

const MIX_RATE := 44100.0
const BUFFER_LENGTH := 0.08
const VOLUME_SMOOTH := 14.0
const MIN_SPEED_PX_S := 30.0
const MAX_SPEED_PX_S := 900.0
const BASE_VOLUME_DB := -14.0
const LINE_MODE_DB_OFFSET := -5.0
const NOISE_AMP := 0.28

var _target_level := 0.0
var _current_level := 0.0
var _line_mode := false
var _noise_state := 0.0


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	bus = &"SFX"
	volume_db = BASE_VOLUME_DB
	play()


func set_line_mode(enabled: bool) -> void:
	_line_mode = enabled
	_apply_bus_volume()


func set_move_speed_px_s(speed: float) -> void:
	var t := clampf((speed - MIN_SPEED_PX_S) / (MAX_SPEED_PX_S - MIN_SPEED_PX_S), 0.0, 1.0)
	_target_level = t * t


func stop_friction() -> void:
	_target_level = 0.0


func _process(delta: float) -> void:
	_current_level = lerpf(_current_level, _target_level, clampf(delta * VOLUME_SMOOTH, 0.0, 1.0))
	var playback := get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var amp := _current_level * NOISE_AMP
	while playback.get_frames_available() > 0:
		if amp <= 0.0005:
			playback.push_frame(Vector2.ZERO)
			continue
		# Simple low-pass filtered noise reads closer to paper friction than raw white noise.
		var white := randf_range(-1.0, 1.0)
		_noise_state = lerpf(_noise_state, white, 0.22)
		var sample := _noise_state * amp
		playback.push_frame(Vector2(sample, sample))


func _apply_bus_volume() -> void:
	volume_db = BASE_VOLUME_DB + (LINE_MODE_DB_OFFSET if _line_mode else 0.0)
