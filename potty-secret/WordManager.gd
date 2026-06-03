extends Node

var active_queue: Array[String] = []

var current_toilet_words: Array[String] = []
var current_toilet_canonicals: Array[String] = []

var good_ending: bool = false
var shift_score: float = 0.0

## Variant modes for display_variants().
## CANONICAL   → return the canonical string itself.
## TYPO        → return the typos pool (falls back to [canonical] if empty).
## SYNONYM     → return the synonyms pool (falls back to [canonical] if empty).
## TYPO_OR_SYNONYM → return typos + synonyms combined (falls back to [canonical] if both empty).
enum VariantMode { CANONICAL, TYPO, SYNONYM, TYPO_OR_SYNONYM }

## Topic pack ids. Only one pack is active per shift for now; more unlock as levels later.
const TOPIC_ALIENS := "aliens"
const TOPIC_CRYPTIDS := "cryptids"
const TOPIC_CONSPIRACY := "conspiracy"
const TOPIC_POP_CULTURE := "pop_culture"

## Active word pack for this build. Gameplay draws planted words, decoys, and lookups from here.
var active_topic_id: String = TOPIC_ALIENS


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Word entries for the active topic. Other code should treat this as the live pool.
var master_list: Array[Dictionary]:
	get:
		var result: Array[Dictionary] = []
		for entry in _active_entries():
			result.append(entry)
		return result


## Returns count distinct canonicals sampled without replacement from the active topic.
## Caller can call display_variants() per canonical to get the actual display form.
func pick_random_canonicals(count: int) -> Array[String]:
	var pool: Array[String] = []
	for entry in _active_entries():
		pool.append(entry["canonical"])
	pool.shuffle()
	var result: Array[String] = []
	for i in range(mini(count, pool.size())):
		result.append(pool[i])
	return result


## Delegates to pick_random_canonicals so existing callers (_roll_toilet_intel
## via game2.gd) receive canonical strings.
## NOTE: strings returned are canonicals — no obfuscation yet. Task-03 will
## replace this call site with a variant-aware path.
func pick_random_words(count: int) -> Array[String]:
	return pick_random_canonicals(count)


func get_next_batch(count: int = 4) -> Array[String]:
	if active_queue.size() < count:
		_refill_queue()

	var batch: Array[String] = []
	for i in range(count):
		batch.append(active_queue.pop_front())

	return batch


## Vestigial queue used by the old paper.gd flow — may be removed in a later
## phase once all callers are confirmed dead.
func _refill_queue():
	active_queue = []
	for entry in _active_entries():
		active_queue.append(entry["canonical"])
	active_queue.shuffle()


## Reverse-lookup: given any display form (canonical, typo, or synonym),
## return the canonical string.  Input is normalised (lowercased, strip
## non-alphanumerics) before comparison.  Returns "" if not found.
##
## Logic mirrors text_renderer.gd._normalize_word but is inlined here to
## avoid a cross-class dependency from WordManager into TextRenderer.
func canonicalize(word: String) -> String:
	var norm := _normalize(word)
	for entry in _active_entries():
		if _normalize(entry["canonical"]) == norm:
			return entry["canonical"]
		for t in entry["typos"]:
			if _normalize(t) == norm:
				return entry["canonical"]
		for s in entry["synonyms"]:
			if _normalize(s) == norm:
				return entry["canonical"]
	return ""


## Returns the display-variant pool for a canonical according to mode.
## canonical must match the "canonical" field exactly (case-sensitive).
## Returns [] if canonical is not found at all (programmer error).
func display_variants(canonical: String, mode: VariantMode) -> Array[String]:
	for entry in _active_entries():
		if entry["canonical"] == canonical:
			var typos: Array[String] = []
			for t in entry["typos"]:
				typos.append(t)
			var synonyms: Array[String] = []
			for s in entry["synonyms"]:
				synonyms.append(s)
			match mode:
				VariantMode.CANONICAL:
					return [canonical]
				VariantMode.TYPO:
					if not typos.is_empty():
						return typos
					return [canonical]
				VariantMode.SYNONYM:
					if not synonyms.is_empty():
						return synonyms
					return [canonical]
				VariantMode.TYPO_OR_SYNONYM:
					var pool: Array[String] = []
					pool.append_array(typos)
					pool.append_array(synonyms)
					if not pool.is_empty():
						return pool
					return [canonical]
	# canonical not found — programmer error
	return []


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _active_entries() -> Array:
	return _topics.get(active_topic_id, [])


## Normalise a word for lookup: lowercase, keep only a-z 0-9.
## Mirrors text_renderer.gd._normalize_word — inlined to avoid cross-dependency.
func _normalize(value: String) -> String:
	var lowered := value.to_lower()
	var output := ""
	for i in range(lowered.length()):
		var code := lowered.unicode_at(i)
		var is_letter := code >= 97 and code <= 122
		var is_number  := code >= 48 and code <= 57
		if is_letter or is_number:
			output += char(code)
	return output


# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------

var templates: Array[String] = [
	"Resident {name} was overheard discussing {illegal_a} at a diner on Route 9. Two unidentified men joined the table before the discussion ended. Witnesses report the same conversation later turned to {illegal_b}.",
	"Subject {name} distributed printed material concerning {illegal_a}. Several copies were recovered from a public bulletin board. Field notes reference an unauthorized gathering about {illegal_b} the following evening.",
	"{name} attended a private meeting focused on {illegal_a}. Attendance was tracked through a side-door log. Recorded minutes include repeated praise for {illegal_b}.",
	"Search of the residence registered to {name} uncovered photographs alleged to depict {illegal_a}. The photographs were stored inside a hollowed dictionary. A separate folder held correspondence regarding {illegal_b}.",
	"Surveillance log shows {name} held a long phone call concerning {illegal_a} on Monday evening. The same line was used Tuesday for a discussion of {illegal_b}. A third call on Thursday referenced {illegal_c}. No business activity was logged in between.",
	"Postal interception of mail addressed to {name} recovered envelopes referencing {illegal_a}. A separate package included sketches related to {illegal_b}. A handwritten letter inside a magazine described {illegal_c}. None of the senders provided return addresses.",
	"Informant reports {name} hosted a basement gathering where attendees discussed {illegal_a}. Pamphlets concerning {illegal_b} were stacked near the entrance. A reel-to-reel film about {illegal_c} was screened after midnight. The basement window was covered with newsprint throughout.",
	"Wiretap transcript shows {name} placed a call regarding {illegal_a} on the first of the month. A follow-up call on the eighth concerned {illegal_b}. A third call before the twentieth referenced {illegal_c}. All three were placed from the same pay phone.",
	"Customs flagged a parcel sent to {name} containing photographs of {illegal_a}. A sealed envelope inside held audio recordings about {illegal_b}. Printed material referencing {illegal_c} was wrapped in plain butcher paper. The declared contents were listed as kitchen supplies.",
	"Bureau investigators believe {name} maintains active interest in {illegal_a}. Field notes record secondary involvement in {illegal_b}. Recent inquiries also concern {illegal_c}. No employer of record has been identified for the past nine months.",
	"School board complaint alleges {name} raised {illegal_a} during a parent meeting. Comparisons to {illegal_b} were drawn during the public comment period. Suggested reading material referenced {illegal_c}. Three parents filed signed statements the following week.",
	"Library records show {name} requested texts on {illegal_a}. The same card was used to check out periodicals concerning {illegal_b}. A reservation for microfilm referencing {illegal_c} was placed by phone. No materials have been returned.",
	"{name} was photographed at a roadside motel meeting three unidentified parties. The first party spoke at length about {illegal_a}. A second guest raised {illegal_b} during the meal. The third departed after a brief exchange concerning {illegal_c}.",
	"Workplace memo flags {name} for repeatedly raising {illegal_a} during shift breaks. Bulletins about {illegal_b} were found posted near the time clock. Typewritten notes on {illegal_c} were recovered from the supply closet. Two coworkers requested transfer to a different shift.",
	"Report mentions {illegal_a} literature distribution by subject {name}. Pamphlets were recovered from coin laundries and a public library reading room. A separate fold of papers concerning {illegal_b} was discovered in the same delivery bag.",
	"Bureau profile lists {name} among known sympathizers of {illegal_a}. Attendance records confirm participation in a regional conference on {illegal_b} last spring. Personal correspondence references an underground reading group focused on {illegal_c}. Tax filings for the group remain incomplete.",
	"Field office report identifies {name} as an organizer within the wider movement around {illegal_a}. The same report notes friendly correspondence with leaders associated with {illegal_b}. No formal employment has been recorded for the subject since 1962.",
	"Public records show {name} delivered an unticketed lecture on {illegal_a} at the community center. The advertised flyer also promised a Q&A regarding {illegal_b}. Attendance figures were not reported to local authorities.",
	"Informant identifies {name} as a vocal believer in {illegal_a}. The same source recalls a private statement of support for {illegal_b}. Subject has been observed distributing reading material on {illegal_c} outside the post office. None of the materials carry an author imprint.",
]


# ---------------------------------------------------------------------------
# Topic word packs — canonical entries with typo and synonym pools
#
# Typos are plausible single-character typewriter slips:
#   adjacent-key swap, doubled letter, missed letter, transposition.
# Synonyms are reasonable clerk-written substitutes for the canonical.
# Multi-word canonicals use single-word synonyms where sensible; typos
#   do not span the space boundary.
#
# Only active_topic_id is used at runtime. Other packs stay ready for future levels.
# ---------------------------------------------------------------------------

var _topics: Dictionary = {
	TOPIC_ALIENS: [
		{
			"canonical": "aliens",
			"typos":    ["ailens", "aloiens", "alienz", "alieens"],
			"synonyms": ["Them", "space people", "visitors"],
		},
		{
			"canonical": "UFOs",
			"typos":    ["UF0s", "UFOss", "ufos"],
			"synonyms": ["bogeys", "unidentified objects"],
		},
		{
			"canonical": "flying saucers",
			"typos":    ["flying saucres", "flyng saucers"],
			"synonyms": ["flying discs", "alien ships"],
		},
		{
			"canonical": "abductions",
			"typos":    ["abductins", "abdcutions", "abductionns"],
			"synonyms": ["takings", "kidnappings"],
		},
		{
			"canonical": "reptilians",
			"typos":    ["reptilans", "reptilions", "reptelians"],
			"synonyms": ["lizard men", "snake people"],
		},
		{
			"canonical": "Area 51",
			"typos":    ["Area 15", "areas 51", "Aera 51"],
			"synonyms": ["Secret Base", "Zone 51"],
		},
		{
			"canonical": "Roswell",
			"typos":    ["roswell", "Rosswell", "Roswel", "Rosswel"],
			"synonyms": ["crash site", "incident 1947"],
		},
		{
			"canonical": "close encounters",
			"typos":    ["close encouters", "close encountrs"],
			"synonyms": ["contact events"],
		},
		{
			"canonical": "cattle mutilations",
			"typos":    ["cattle mutilatins", "cattel mutilations"],
			"synonyms": ["livestock incidents", "cow mutilations"],
		},
	],
	TOPIC_CRYPTIDS: [
		{
			"canonical": "bigfoot",
			"typos":    ["bigfooot", "bifoot", "bigfot"],
			"synonyms": ["sasquatch", "the hairy creature"],
		},
		{
			"canonical": "Mothman",
			"typos":    ["Mothmen", "Mothmann", "Mothnman"],
			"synonyms": ["Fly Man", "Bug Man"],
		},
		{
			"canonical": "Nessie",
			"typos":    ["Nesie", "Nessye", "Nesssi"],
			"synonyms": ["lake monster", "the serpent"],
		},
		{
			"canonical": "chupacabra",
			"typos":    ["chupacabara", "chupaccabra", "chupacabrs"],
			"synonyms": ["the goat sucker", "el chupas"],
		},
		{
			"canonical": "the Yeti",
			"typos":    ["the Yeeti", "the Yetti"],
			"synonyms": ["snow creature", "snowman"],
		},
	],
	TOPIC_CONSPIRACY: [
		{
			"canonical": "MKUltra",
			"typos":    ["MKUlrta", "MkUltra", "MKUltraa", "MKUlra"],
			"synonyms": ["Secret Program", "Secret Experiment"],
		},
		{
			"canonical": "chemtrails",
			"typos":    ["chemtrils", "chemtrales", "chemtraills"],
			"synonyms": ["sky lines", "sky chemicals"],
		},
		{
			"canonical": "Illuminati",
			"typos":    ["Iluminati", "Illumnati", "Illuminatti"],
			"synonyms": ["the order", "the brotherhood"],
		},
		{
			"canonical": "the deep state",
			"typos":    ["the deep staet", "the depp state"],
			"synonyms": [],
		},
		{
			"canonical": "Bilderberg",
			"typos":    ["Bilderburg", "Bilerberg", "Bilderberq"],
			"synonyms": ["Secret Group"],
		},
		{
			"canonical": "New World Order",
			"typos":    ["New Wrold Order", "New World Ordr"],
			"synonyms": ["Secret Plan"],
		},
		{
			"canonical": "the Bermuda Triangle",
			"typos":    ["the Bermuda Triange", "the Bermuda Triangel"],
			"synonyms": [],
		},
		{
			"canonical": "the Moon Landing",
			"typos":    ["the Moon Lnading", "the Moon Landign"],
			"synonyms": ["the Moon trip", "the Moon visit"],
		},
		{
			"canonical": "Hollow Earth",
			"typos":    ["Holloow Earth", "Hollow Eath", "Holllow Earth"],
			"synonyms": ["Agharta"],
		},
		{
			"canonical": "JFK",
			"typos":    ["JFk", "JFK1", "JGK"],
			"synonyms": ["killed president", "Dallas thing", "jfk"],
		},
	],
	TOPIC_POP_CULTURE: [
		{
			"canonical": "Elvis",
			"typos":    ["Evlis", "Elviss", "Elvls"],
			"synonyms": ["the King", "Presley"],
		},
		{
			"canonical": "Big Secret",
			"typos":    ["Biq Secret", "Big Secreet"],
			"synonyms": ["The Secret", "Beautiful Secret"],
		},
		{
			"canonical": "Tupac",
			"typos":    ["Tupak", "Tupca", "Tupacc"],
			"synonyms": ["2Pac", "Secret Rapper"],
		},
	],
}


var names: Array[String] = [
	"Frank Holloway",
	"Margaret Whitaker",
	"Earl Pemberton",
	"Linda Calloway",
	"Hank Doyle",
	"Bob Lazarus",
	"Stan Freedman",
	"J. Allen Hyneker",
	"Linda Howemoulton",
	"Erich von Donut",
	"Whit Strieberg",
	"J. Edna Hoover",
	"Buford Crumpacker",
	"Mildred Sneed",
	"Eustace Boggs",
	"Delbert Tubbs",
	"Norma Jean Pickens",
	"Cletus Crampton",
	"Elvis P. Reasley",
	"Marilyn O'Monroe",
	"Vincent J. F. Kennetty",
]
