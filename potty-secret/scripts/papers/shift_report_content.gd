class_name ShiftReportContent

const REPORT_TARGETS: Array[String] = ["accept", "accept"]


static func report_text(score: float, memos_processed: int, stamps: int) -> String:
	var score_str: String
	if score > 0.0:
		score_str = "+%.1f" % score
	else:
		score_str = "%.1f" % score
	var disposition := _disposition(score)
	return (
		"SHIFT CLOSURE REPORT — FORM 47-B (REV. NEVER).\n\n"
		+ "Aggregate shift score: %s.\n"
		+ "Memos processed: %d.\n"
		+ "Perfect sheets stamped: %d.\n"
		+ "Compliance disposition: %s.\n\n"
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
