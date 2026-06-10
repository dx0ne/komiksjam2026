extends PointLight2D

signal flicker_off
signal flicker_on
signal mode_changed(mode: Mode)

const TENSION_START_S := 10.0

enum Mode { STEADY, TENSION }
enum Override { AUTO, FORCE_OFF, FORCE_ON }

var _base_energy: float
var _override := Override.AUTO
var _clock: ShiftClock
var _mode := Mode.STEADY
var _lit := true
var _countdown_second := -1


func _ready() -> void:
	_base_energy = energy
	_clock = owner.get_node_or_null("%clock_scn") as ShiftClock
	set_process(true)
	_set_steady_on()


func _process(_delta: float) -> void:
	_update_mode()


func force_lamp(on: bool) -> void:
	_override = Override.FORCE_ON if on else Override.FORCE_OFF
	_countdown_second = -1
	if on:
		_set_steady_on()
	else:
		_set_steady_off()


func release_lamp_override() -> void:
	_override = Override.AUTO
	_countdown_second = -1
	_update_mode()


func _update_mode() -> void:
	if _override != Override.AUTO:
		return
	var time_left := _get_time_left()
	if time_left > TENSION_START_S:
		if _mode != Mode.STEADY:
			_set_mode(Mode.STEADY)
	elif time_left > 0.0:
		if _mode != Mode.TENSION:
			_set_mode(Mode.TENSION)
		_sync_countdown_lamp(time_left)
	else:
		if _mode != Mode.STEADY:
			_set_mode(Mode.STEADY)
		_set_steady_off()


func _get_time_left() -> float:
	if _clock == null or _clock.game_timer.is_stopped():
		return INF
	return _clock.time_left


func _set_mode(mode: Mode) -> void:
	if _mode == mode:
		return
	_mode = mode
	mode_changed.emit(mode)
	match mode:
		Mode.STEADY:
			_countdown_second = -1
			_set_steady_on()
		Mode.TENSION:
			_countdown_second = -1
			_sync_countdown_lamp(_get_time_left())


func _sync_countdown_lamp(time_left: float) -> void:
	var sec := int(floor(time_left))
	if sec <= 0:
		_set_steady_off()
		return
	if sec == _countdown_second:
		return
	_countdown_second = sec
	if sec % 2 == 0:
		_set_steady_on()
	else:
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
