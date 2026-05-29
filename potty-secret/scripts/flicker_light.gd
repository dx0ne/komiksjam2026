extends PointLight2D

signal flicker_off
signal flicker_on

@export var flicker_interval_min: float = 15.0
@export var flicker_interval_max: float = 25.0
@export var flicker_blinks_min: int = 3
@export var flicker_blinks_max: int = 5
@export var flicker_on_time_min: float = 0.04
@export var flicker_on_time_max: float = 0.12
@export var flicker_off_time_min: float = 0.04
@export var flicker_off_time_max: float = 0.15

var _base_energy: float
var _timer: Timer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_base_energy = energy
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_schedule_next_burst()


func _schedule_next_burst() -> void:
	_timer.start(_rng.randf_range(flicker_interval_min, flicker_interval_max))


func _on_timer_timeout() -> void:
	_run_burst()


func _run_burst() -> void:
	var blinks := _rng.randi_range(flicker_blinks_min, flicker_blinks_max)
	for i in range(blinks):
		energy = 0.0
		flicker_off.emit()
		await get_tree().create_timer(_rng.randf_range(flicker_off_time_min, flicker_off_time_max)).timeout
		energy = _base_energy
		flicker_on.emit()
		await get_tree().create_timer(_rng.randf_range(flicker_on_time_min, flicker_on_time_max)).timeout
	energy = _base_energy
	_schedule_next_burst()
