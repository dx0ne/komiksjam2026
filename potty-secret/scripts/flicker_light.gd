extends PointLight2D

signal flicker_off
signal flicker_on

const TENSION_START_S := 10.0
const FINAL_DARK_START_S := 3.0

@export var tension_interval_min: float = 0.6
@export var tension_interval_max: float = 1.8
@export var flicker_blinks_min: int = 3
@export var flicker_blinks_max: int = 5
@export var flicker_on_time_min: float = 0.04
@export var flicker_on_time_max: float = 0.12
@export var flicker_off_time_min: float = 0.04
@export var flicker_off_time_max: float = 0.15

enum Mode { STEADY, TENSION, DARK }
enum Override { AUTO, FORCE_OFF, FORCE_ON }

var _base_energy: float
var _override := Override.AUTO
var _timer: Timer
var _rng := RandomNumberGenerator.new()
var _clock: ShiftClock
var _mode := Mode.STEADY
var _burst_running := false
var _abort_burst := false
var _lit := true


func _ready() -> void:
	_rng.randomize()
	_base_energy = energy
	_clock = owner.get_node_or_null("%clock_scn") as ShiftClock
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	set_process(true)
	_set_steady_on()


func _process(_delta: float) -> void:
	_update_mode()


func force_lamp(on: bool) -> void:
	_override = Override.FORCE_ON if on else Override.FORCE_OFF
	_stop_burst()
	if on:
		_set_steady_on()
	else:
		_set_steady_off()


func release_lamp_override() -> void:
	_override = Override.AUTO
	_update_mode()


func _update_mode() -> void:
	if _override != Override.AUTO:
		return
	var time_left := _get_time_left()
	if time_left <= FINAL_DARK_START_S:
		_set_mode(Mode.DARK)
	elif time_left <= TENSION_START_S:
		_set_mode(Mode.TENSION)
	else:
		_set_mode(Mode.STEADY)


func _get_time_left() -> float:
	if _clock == null or _clock.game_timer.is_stopped():
		return INF
	return _clock.time_left


func _set_mode(mode: Mode) -> void:
	if _mode == mode:
		return
	_mode = mode
	match mode:
		Mode.STEADY:
			_stop_burst()
			_set_steady_on()
		Mode.TENSION:
			_stop_burst()
			_set_steady_on()
			_run_burst()
		Mode.DARK:
			_stop_burst()
			_set_steady_off()


func _set_steady_on() -> void:
	if _lit:
		return
	_lit = true
	energy = _base_energy
	flicker_on.emit()


func _set_steady_off() -> void:
	if not _lit:
		return
	_lit = false
	energy = 0.0
	flicker_off.emit()


func _stop_burst() -> void:
	_abort_burst = true
	_timer.stop()


func _schedule_next_burst() -> void:
	if _mode != Mode.TENSION:
		return
	_timer.start(_rng.randf_range(tension_interval_min, tension_interval_max))


func _on_timer_timeout() -> void:
	if _mode != Mode.TENSION:
		return
	_run_burst()


func _run_burst() -> void:
	if _mode != Mode.TENSION:
		return
	_burst_running = true
	_abort_burst = false
	var blinks := _rng.randi_range(flicker_blinks_min, flicker_blinks_max)
	for i in range(blinks):
		if _abort_burst or _mode != Mode.TENSION:
			break
		_lit = false
		energy = 0.0
		flicker_off.emit()
		await get_tree().create_timer(_rng.randf_range(flicker_off_time_min, flicker_off_time_max)).timeout
		if _abort_burst or _mode != Mode.TENSION:
			break
		_lit = true
		energy = _base_energy
		flicker_on.emit()
		await get_tree().create_timer(_rng.randf_range(flicker_on_time_min, flicker_on_time_max)).timeout
	_burst_running = false
	if _mode == Mode.TENSION and not _abort_burst:
		_set_steady_on()
		_schedule_next_burst()
