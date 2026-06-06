class_name DocumentScenes

## Maps onboarding steps and topic ids to custom PackedScenes (inherit from paper.tscn).
## Duplicate a scene under scenes/documents/ or scenes/newspapers/ to customize
## backgrounds, TextRenderer bounds, and PostIt / PostItHint layout in the editor.

const DEFAULT_PAPER := preload("res://paper.tscn")

const ONBOARDING: Dictionary = {
	"welcome": preload("res://scenes/documents/onboarding_welcome.tscn"),
	"toilet": preload("res://scenes/documents/onboarding_toilet.tscn"),
	"briefing": preload("res://scenes/documents/onboarding_briefing.tscn"),
	"shift_start": preload("res://scenes/documents/onboarding_shift_start.tscn"),
	"shift_report": preload("res://scenes/documents/shift_report.tscn"),
}

const TOPIC: Dictionary = {
	TopicContent.TOPIC_ALIENS: preload("res://scenes/newspapers/topic_aliens.tscn"),
	TopicContent.TOPIC_CRYPTIDS: preload("res://scenes/newspapers/topic_cryptids.tscn"),
	TopicContent.TOPIC_CONSPIRACY: preload("res://scenes/newspapers/topic_conspiracy.tscn"),
	TopicContent.TOPIC_POP_CULTURE: preload("res://scenes/newspapers/topic_pop_culture.tscn"),
}


static func onboarding(step_key: String) -> PackedScene:
	return ONBOARDING.get(step_key, DEFAULT_PAPER) as PackedScene


static func topic(topic_id: String) -> PackedScene:
	return TOPIC.get(topic_id, DEFAULT_PAPER) as PackedScene
