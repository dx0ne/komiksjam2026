class_name OnboardingContent

const WELCOME_TARGETS: Array[String] = ["accept", "accept"]

## Single toilet-intel strip shown during WELCOME so the player learns intel = forbidden word.
const WELCOME_INTEL: Array[String] = ["accept"]

const WELCOME_TEXT := (
	"WELCOME TO THE SECRET MARKERS\n"
	+ "DIVISION of ████████\n\n"
	+ "We hide what must not be seen. "
	+ "Your marker is your oath. Your desk is your battlefield.\n\n"
	+ "Training, item one: drag your marker across a word to black it out.\n"
	+ "Should you choose to accept this assignment, redact both marks of accept below."
)

const TOILET_TARGETS: Array[String] = ["UFOs", "Area 51"]

const TOILET_PULL_TEXT := (
	"MEMO 7B/∞ — RE: TOILET INTEL COMPLIANCE\n"
	+ "Form 12-Q (rev. B055).\n\n"
	+ "All personnel shall treat posted toilet intel as authoritative "
	+ "for forbidden terms on the active memo. "
	+ "A fresh memo and updated intel strips are issued upon pull of the handle.\n\n"
	+ "Pull the chain to issue the active marking memo."
)

const TOILET_MARK_TEXT := (
	"MEMO 7B/∞ — RE: ACTIVE MARKING ORDERS\n"
	+ "Form 12-Q (rev. B055).\n\n"
	+ "Cross-reference the posted toilet intel against the memo below. "
	+ "Redact all designated forbidden terms before the silence review.\n\n"
	+ "Annex 4 field summaries cite unverified UFOs in logged airspace. "
	+ "The Nevada perimeter file retains Area 51 under standing blackout."
)

const BRIEFING_TARGETS: Array[String] = ["ready", "steady", "go"]

const BRIEFING_TEXT := (
	"SHIFT BRIEFING — 180 SECONDS.\n\n"
	+ "Forbidden words appear on the toilet paper.\n"
	+ "Black them out on the memo. Pull the handle for a new memo and new intel.\n"
	+ "Wrong marks cost you. The coffee mug grants ten extra seconds when sipped.\n\n"
	+ "To begin your shift, redact ready, steady, and go."
)

const SHIFT_START_TARGETS: Array[String] = ["begin"]

const SHIFT_START_TEXT := (
	"SHIFT REOPENING — FORM 9-DUTY.\n\n"
	+ "One hundred eighty seconds await on the clock.\n"
	+ "Toilet intel is posted.\n\n"
	+ "Redact begin to commence your shift."
)

static func toilet_pull_text() -> String:
	return TOILET_PULL_TEXT


static func toilet_mark_text() -> String:
	return TOILET_MARK_TEXT


static func briefing_text() -> String:
	return BRIEFING_TEXT


static func shift_start_text() -> String:
	return SHIFT_START_TEXT
