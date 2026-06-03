class_name ShiftReportContent

const REPORT_TARGETS: Array[String] = ["accept", "accept"]
const STICKY_HINT := "accept?"


static func report_text(score: float, memos_processed: int, stamps: int) -> String:
	var score_str: String
	if score > 0.0:
		score_str = "+%.1f" % score
	else:
		score_str = "%.1f" % score
	var disposition := _disposition(score)
	return (
		"SHIFT CLOSURE REPORT — FORM 47-B (REV. NEVER). "
		+ "Aggregate shift score: %s. Memos processed: %d. "
		+ "Perfect sheets stamped: %d. Compliance disposition: %s. "
		+ "Should you accept this summary for ministry filing, redact accept."
	) % [score_str, memos_processed, stamps, disposition]


static func _disposition(score: float) -> String:
	if score >= 15.0:
		return "EXEMPLARY"
	if score > 0.0:
		return "SATISFACTORY"
	if score == 0.0:
		return "MARGINAL"
	return "UNSATISFACTORY"
