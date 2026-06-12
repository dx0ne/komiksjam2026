extends Node

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_AMBIENT := &"Ambient"
const BUS_SFX := &"SFX"

const SFX_PATHS := {
	"coffee_sip": "res://audio/sfx/coffee_sip.mp3",
	"clock_time_ping": "res://audio/sfx/clock_time_ping.mp3",
	"mug_set_down": "res://audio/sfx/mug_set_down.mp3",
	"cigarette_puff": "res://audio/sfx/cigarette_puff.mp3",
	"cigarette_on_ashtray": "res://audio/sfx/cigarette_on_ashtray.mp3",
	"hand_twitch": "res://audio/sfx/hand_twitch.mp3",
	"fly_erase_click": "res://audio/sfx/fly_erase_click.mp3",
	"wrong_mark_accent": "res://audio/sfx/wrong_mark_accent.mp3",
	"mug_smear": "res://audio/sfx/mug_smear.mp3",
	"stamp_slam": "res://audio/sfx/stamp_slam.mp3",
	"memo_spawn": "res://audio/sfx/memo_spawn.mp3",
	"shift_report_arrive": "res://audio/sfx/shift_report_arrive.mp3",
	"toilet_handle_pull": "res://audio/sfx/toilet_handle_pull.mp3",
	"intel_strip_spawn": "res://audio/sfx/intel_strip_spawn.mp3",
	"handle_attract_creak": "res://audio/sfx/handle_attract_creak.mp3",
	"lamp_flicker_click": "res://audio/sfx/lamp_flicker_click.mp3",
	"lamp_final_off": "res://audio/sfx/lamp_final_off.mp3",
	"lamp_relight": "res://audio/sfx/lamp_relight.mp3",
	"menu_play_confirmed": "res://audio/sfx/menu_play_confirmed.mp3",
	"menu_save_wipe": "res://audio/sfx/menu_save_wipe.mp3",
}

const MUSIC_PATHS := {
	"menu_ambient_loop": "res://audio/music/menu_ambient_loop.mp3",
	"shift_ambient_loop": "res://audio/music/shift_ambient_loop.mp3",
}

const ONE_SHOT_POOL_SIZE := 10
const AMBIENT_FADE_S := 0.8
## 70% linear amplitude vs default SFX level (20*log10(0.7)).
const PAPER_TOILET_INTEL_VOLUME_DB := -2.1
## 50% linear amplitude (20*log10(0.5)).
const MENU_AMBIENT_VOLUME_DB := -6.0

var _streams: Dictionary = {}
var _one_shot_pool: Array[AudioStreamPlayer] = []
var _one_shot_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _music_fade_tween: Tween
var _ambient_fade_tween: Tween


func _ready() -> void:
	_preload_streams()
	_build_one_shot_pool()
	_music_player = _make_loop_player(BUS_MUSIC)
	_ambient_player = _make_loop_player(BUS_AMBIENT)


func play_sfx(
	key: String,
	pitch_scale: float = 1.0,
	volume_db: float = 0.0,
	bus: StringName = BUS_SFX
) -> void:
	var stream: AudioStream = _streams.get(key)
	if stream == null:
		push_warning("AudioManager: missing SFX '%s'" % key)
		return
	var player := _next_one_shot_player()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.bus = bus
	player.play()


func play_menu_ambient() -> void:
	stop_shift_ambient(true)
	_start_ambient_track("menu_ambient_loop", BUS_MUSIC, MENU_AMBIENT_VOLUME_DB)


func play_shift_ambient() -> void:
	_start_ambient_track("shift_ambient_loop", BUS_AMBIENT)


func stop_menu_ambient(immediate: bool = false) -> void:
	_stop_loop_player(_music_player, immediate)


func stop_shift_ambient(immediate: bool = false) -> void:
	_stop_loop_player(_ambient_player, immediate)


func play_paper_sfx(key: String) -> void:
	play_sfx(key, 1.0, PAPER_TOILET_INTEL_VOLUME_DB)


func play_toilet_intel_sfx(key: String) -> void:
	play_sfx(key, 1.0, PAPER_TOILET_INTEL_VOLUME_DB)


func _preload_streams() -> void:
	for key in SFX_PATHS:
		_streams[key] = _load_stream(SFX_PATHS[key], key.ends_with("_loop"))
	for key in MUSIC_PATHS:
		_streams[key] = _load_stream(MUSIC_PATHS[key], true)


func _load_stream(path: String, loop: bool) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing file %s" % path)
		return null
	var stream: AudioStream = load(path)
	if stream == null:
		return null
	if loop and stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	return stream


func _build_one_shot_pool() -> void:
	for i in ONE_SHOT_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_one_shot_pool.append(player)


func _make_loop_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _next_one_shot_player() -> AudioStreamPlayer:
	var player := _one_shot_pool[_one_shot_index]
	_one_shot_index = (_one_shot_index + 1) % ONE_SHOT_POOL_SIZE
	if player.playing:
		player.stop()
	return player


func _start_ambient_track(track_key: String, bus: StringName, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(track_key)
	if stream == null:
		return
	var player := _music_player if bus == BUS_MUSIC else _ambient_player
	if player.stream == stream and player.playing:
		return
	_kill_fade_tween(player)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()


func _stop_loop_player(player: AudioStreamPlayer, immediate: bool) -> void:
	if immediate:
		_kill_fade_tween(player)
		player.stop()
		player.volume_db = 0.0
		return
	if player.playing:
		_fade_out_player(player)


func _fade_tween_for(player: AudioStreamPlayer) -> Tween:
	return _music_fade_tween if player == _music_player else _ambient_fade_tween


func _set_fade_tween(player: AudioStreamPlayer, tween: Tween) -> void:
	if player == _music_player:
		_music_fade_tween = tween
	else:
		_ambient_fade_tween = tween


func _kill_fade_tween(player: AudioStreamPlayer) -> void:
	var tween := _fade_tween_for(player)
	if tween and tween.is_valid():
		tween.kill()


func _fade_out_player(player: AudioStreamPlayer, duration: float = AMBIENT_FADE_S) -> void:
	if not player.playing:
		return
	_kill_fade_tween(player)
	var start_db := player.volume_db
	var tween := create_tween()
	_set_fade_tween(player, tween)
	tween.tween_method(
		func(value: float) -> void: player.volume_db = value,
		start_db,
		-40.0,
		duration
	)
	tween.tween_callback(func() -> void:
		player.stop()
		player.volume_db = start_db
	)
