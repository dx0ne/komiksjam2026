class_name OnboardingContent

const WELCOME_TARGETS: Array[String] = ["accept", "accept"]

const WELCOME_TEXT := (
	"WELCOME TO THE SECRET MARKERS — CLASSIFIED DIVISION "
	+ "(MINISTRY OF SILLY REDACTIONS). We hide what must not be seen. "
	+ "Your marker is your oath. Your desk is your battlefield. "
	+ "Should you choose to accept this assignment, redact accept."
)

const TOILET_TARGETS: Array[String] = ["UFOs", "Area 51"]

const TOILET_TEXT := (
	"MEMO 7B/∞ — RE: interdepartmental flux capacitor audit pursuant to "
	+ "Form 12-Q (rev. never). All personnel shall cross-reference UFOs "
	+ "with Area 51 before the quarterly silence review. "
	+ "This message will self-destruct in your plumbing. "
	+ "If you choose to proceed, pull the handle and redact the words from the toilet paper."
)

const BRIEFING_TARGETS: Array[String] = ["ready", "steady", "go"]

const BRIEFING_TEXT := (
	"SHIFT BRIEFING — 180 SECONDS. Forbidden words appear on the toilet paper. "
	+ "Black them out on the memo. Pull the handle for a new memo and new intel. "
	+ "Wrong marks cost you. The coffee mug grants ten extra seconds when sipped. "
	+ "To begin your shift, redact ready, steady, and go."
)

const SHIFT_START_TARGETS: Array[String] = ["begin"]

const SHIFT_START_TEXT := (
	"SHIFT REOPENING — FORM 9-DUTY. One hundred eighty seconds await on the clock. "
	+ "Toilet intel is posted. Redact begin to commence your shift."
)

static func toilet_text() -> String:
	return TOILET_TEXT


static func briefing_text() -> String:
	return BRIEFING_TEXT


static func shift_start_text() -> String:
	return SHIFT_START_TEXT
