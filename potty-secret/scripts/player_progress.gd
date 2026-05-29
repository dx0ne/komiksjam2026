extends Node

const PATH := "user://progress.cfg"

var _onboarding_complete: bool = false


func _ready() -> void:
	_load()


func has_completed_onboarding() -> bool:
	return _onboarding_complete


func mark_onboarding_complete() -> void:
	_onboarding_complete = true
	_save()


func reset_onboarding() -> void:
	_onboarding_complete = false
	_save()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	_onboarding_complete = cfg.get_value("progress", "onboarding_complete", false)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "onboarding_complete", _onboarding_complete)
	cfg.save(PATH)
