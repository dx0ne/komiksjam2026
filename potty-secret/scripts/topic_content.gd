class_name TopicContent

## Lore and newspaper copy for each playable topic / level.

const TOPIC_ALIENS := "aliens"
const TOPIC_CRYPTIDS := "cryptids"
const TOPIC_CONSPIRACY := "conspiracy"
const TOPIC_POP_CULTURE := "pop_culture"

const POST_IT_DEFAULT := "We need to clean this up"

const TOPICS: Dictionary = {
	TOPIC_ALIENS: {
		"paper_name": "THE CAPITAL SCOOP",
		"headline": "PRESIDENT EAGLE TO REVEAL TRUTH ABOUT ALIENS!",
		"deck": (
			"Leak promises disclosure at tonight's briefing — "
			+ "hours later, the story is 'under review'"
		),
		"body": (
			"WASHINGTON — The press obtained what sources describe as a draft "
			+ "statement from President Eagle pledging to release long-classified "
			+ "files on extraterrestrial contact, UFO sightings, and alleged abductions. "
			+ "White House staff reportedly spent the afternoon in crisis meetings "
			+ "ahead of the scheduled address. A senior aide, speaking on condition "
			+ "of anonymity, said the President had 'changed his mind about transparency.'"
		),
		"post_it": POST_IT_DEFAULT,
	},
	TOPIC_CRYPTIDS: {
		"paper_name": "THE CAPITAL SCOOP",
		"headline": "PRESIDENT EAGLE TO REVEAL TRUTH ABOUT CRYPTIDS!",
		"deck": "Forest service files said to name names — briefing pulled at last minute",
		"body": (
			"WASHINGTON — Reporters were told President Eagle would address decades of "
			+ "suppressed field reports on sasquatch, lake monsters, and other creatures "
			+ "logged by federal survey teams. The promised release never materialized."
		),
		"post_it": POST_IT_DEFAULT,
	},
	TOPIC_CONSPIRACY: {
		"paper_name": "THE CAPITAL SCOOP",
		"headline": "PRESIDENT EAGLE TO REVEAL TRUTH ABOUT THE DEEP STATE!",
		"deck": "Cabinet memo leaked — then every copy in the building vanished",
		"body": (
			"WASHINGTON — A photocopied directive suggested President Eagle would "
			+ "declassify internal correspondence on secret programs and shadow councils. "
			+ "By dusk, editors were calling it the leak that leaked back."
		),
		"post_it": POST_IT_DEFAULT,
	},
	TOPIC_POP_CULTURE: {
		"paper_name": "THE CAPITAL SCOOP",
		"headline": "PRESIDENT EAGLE TO REVEAL TRUTH ABOUT THE KING!",
		"deck": "Elvis files? Tupac tapes? The scoop nobody was ready for",
		"body": (
			"WASHINGTON — Entertainment desks received a tip that President Eagle "
			+ "would finally open the vault on celebrity cover-ups the public has "
			+ "whispered about for years. The briefing room doors stayed locked."
		),
		"post_it": POST_IT_DEFAULT,
	},
}


static func get_topic(topic_id: String) -> Dictionary:
	if TOPICS.has(topic_id):
		return TOPICS[topic_id]
	return TOPICS[TOPIC_ALIENS]
