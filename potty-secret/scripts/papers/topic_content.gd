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
		"post_it_hint": "aliens (headline)",
		"targets": ["aliens"],
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
		"post_it_hint": "mark CRYPTIDS",
		"targets": ["CRYPTIDS"],
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
		"post_it_hint": "mark DEEP",
		"targets": ["DEEP"],
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
		"post_it_hint": "mark KING",
		"targets": ["KING"],
	},
}


static func targets_from_data(data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Array = data.get("targets", [])
	for t in raw:
		out.append(str(t))
	return out


static func build_document_text(data: Dictionary) -> String:
	if data.has("document_text"):
		return str(data["document_text"])
	var parts: PackedStringArray = []
	var paper_name: String = data.get("paper_name", "")
	if not paper_name.is_empty():
		parts.append(paper_name)
	var headline: String = data.get("headline", "")
	if not headline.is_empty():
		parts.append(headline)
	var deck: String = data.get("deck", "")
	if not deck.is_empty():
		parts.append(deck)
	var body: String = data.get("body", "")
	if not body.is_empty():
		parts.append(body)
	return "\n\n".join(parts)


static func get_topic(topic_id: String) -> Dictionary:
	if TOPICS.has(topic_id):
		return TOPICS[topic_id]
	return TOPICS[TOPIC_ALIENS]
