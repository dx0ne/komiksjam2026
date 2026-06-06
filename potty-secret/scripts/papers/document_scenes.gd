class_name DocumentScenes

## Maps onboarding steps and topic ids to custom PackedScenes (inherit from paper.tscn).
## Duplicate a scene under scenes/papers/ to customize
## backgrounds, TextRenderer bounds, and PostIt / PostItHint layout in the editor.

const DEFAULT_PAPER := preload("res://scenes/gameplay/paper.tscn")

const ONBOARDING: Dictionary = {
	"welcome": preload("res://scenes/papers/onboarding_welcome.tscn"),
	"toilet": preload("res://scenes/papers/onboarding_toilet.tscn"),
	"briefing": preload("res://scenes/papers/onboarding_briefing.tscn"),
	"shift_start": preload("res://scenes/papers/onboarding_shift_start.tscn"),
	"shift_report": preload("res://scenes/papers/shift_report.tscn"),
}

const TOPIC: Dictionary = {
	TopicContent.TOPIC_ALIENS: preload("res://scenes/papers/topic_aliens.tscn"),
	TopicContent.TOPIC_CRYPTIDS: preload("res://scenes/papers/topic_cryptids.tscn"),
	TopicContent.TOPIC_CONSPIRACY: preload("res://scenes/papers/topic_conspiracy.tscn"),
	TopicContent.TOPIC_POP_CULTURE: preload("res://scenes/papers/topic_pop_culture.tscn"),
}


static func onboarding(step_key: String) -> PackedScene:
	return ONBOARDING.get(step_key, DEFAULT_PAPER) as PackedScene


static func topic(topic_id: String) -> PackedScene:
	return TOPIC.get(topic_id, DEFAULT_PAPER) as PackedScene
