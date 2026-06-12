class_name OnboardingContent

const WELCOME_TARGETS: Array[String] = ["accept", "accept"]

const WELCOME_TEXT := (
	"WELCOME TO THE SECRET MARKERS\n"
	+ "DIVISION of ████████\n"
	+ "We hide what must not be seen. "
	+ "Your marker is your oath. Your desk is your battlefield.\n\n"
	+ "Should you choose to accept this assignment, redact accept."
)

const TOILET_TARGETS: Array[String] = ["UFOs", "Area 51"]

## One word per toilet strip before the player pulls — spells out "pull the chain".
const TOILET_INTEL_PULL_HINT: Array[String] = ["pull", "the", "chain"]

const TOILET_TEXT := (
	"MEMO 7B/∞ — RE: TOILET INTEL COMPLIANCE\n"
	+ "Form 12-Q (rev. B055).\n\n"
	+ "All personnel shall treat posted toilet intel as authoritative "
	+ "for forbidden terms on the active memo. "
	+ "Updated strips are issued upon pull of the handle; "
	+ "consult each release before marking.\n\n"
	+ "Pending review: UFOs, Area 51 — redact per posted intel."
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

static func toilet_text() -> String:
	return TOILET_TEXT


static func briefing_text() -> String:
	return BRIEFING_TEXT


static func shift_start_text() -> String:
	return SHIFT_START_TEXT
