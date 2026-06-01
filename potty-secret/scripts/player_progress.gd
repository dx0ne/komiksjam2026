extends Node

const PATH := "user://progress.cfg"

var _onboarding_complete: bool = false
var _topics_intro_seen: Dictionary = {}


func _ready() -> void:
	_load()


func has_completed_onboarding() -> bool:
	return _onboarding_complete


func mark_onboarding_complete() -> void:
	_onboarding_complete = true
	_save()


func reset_onboarding() -> void:
	_onboarding_complete = false
	_topics_intro_seen.clear()
	_save()


func has_seen_topic_intro(topic_id: String) -> bool:
	return _topics_intro_seen.get(topic_id, false)


func mark_topic_intro_seen(topic_id: String) -> void:
	_topics_intro_seen[topic_id] = true
	_save()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	_onboarding_complete = cfg.get_value("progress", "onboarding_complete", false)
	_topics_intro_seen = cfg.get_value("progress", "topics_intro_seen", {})


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "onboarding_complete", _onboarding_complete)
	cfg.set_value("progress", "topics_intro_seen", _topics_intro_seen)
	cfg.save(PATH)
